#!/usr/bin/env perl
use strict;
use warnings;
use autodie;

use Cwd qw(getcwd realpath);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(remove_tree);
use Getopt::Long qw(GetOptions);
use Pod::Usage;

=head1 SYNOPSIS

    ./sw360chores.pl [switches] [options] [-- arguments for docker-compose]

  # options
  ## handling images:
    ./sw360chores.pl [switches] [--build] [--save-images]
    ./sw360chores.pl [--cve-search] --prod --build --webapps=s --deploy=s [--save-images]
  ## cleanup state and images
    ./sw360chores.pl [switches] --cleanup
  ## deploy war files
    ./sw360chores.pl [--cp-webapps-from=s] [--cp-deploy-from=s]
  ## backup and restore
    ./sw360chores.pl [switches] --backup=s
    ./sw360chores.pl [switches] --restore=s
  ## controll docker-compose
    ./sw360chores.pl [switches] -- arguments for docker-compose

  # switches
  ## enable productive mode:
    ./sw360chores.pl --prod [options] [-- arguments for docker-compose]
  ## enable cve-search server
    ./sw360chores.pl --cve-search [options] [-- arguments for docker-compose]

  # evironmental variables
    $SW360CHORES_VERSION
      is the version of the chores containers which will be used for tagging
    $SW360_VERSION
      is the version of sw360 which will be used for tagging the productive filled image

  # examples:
  ## build and pull all Images, start the containers and detach:
    ./sw360chores.pl --build -- up -d
  ## view and follow the logs of sw360 on a productive setup
    ./sw360chores.pl --prod -- logs -f sw360
  ## build and save all images
    ./sw360chores.pl --build --save-images
  ## build, tag and save all images including the filled sw360 container. It will be populated with the wars from ./_webapps and ./_deploy
    SW360CHORES_VERSION="3.1.0" SW360_VERSION="3.1.0-SNAPSHOT" ./sw360chores.pl --prod --build --webapps=./_webapps --deploy=./_deploy --save-images
  ## rebuild from scratch
    ./sw360chores.pl --cleanup --build

=cut

my $build = '';
my $save = '';
my $cleanup = '';
my $prod = '';
my $cveSearch = '';
my $cpWebappsDir = '';
my $cpDeployDir = '';
my $backupDir = '';
my $restoreDir = '';
GetOptions (
    # handle imgaes
    'build' => \$build,
    'save|save-images' => \$save,
    'load|load-images' => sub {die "not implemented yet"},
    'push-to=s' => sub {die "not implemented yet"},
    # cleanup
    'cleanup' => \$cleanup,
    # control runtime
    'prod' => \$prod,
    'cve-search' => \$cveSearch,
    'webapps|cp-webapps-from=s' => sub {
        my ($opt_name, $opt_value) = @_;
        $cpWebappsDir = realpath($opt_value);
    },
    'deploy|cp-deploy-from=s' => sub {
        my ($opt_name, $opt_value) = @_;
        $cpDeployDir = realpath($opt_value);
    },
    # backup and restore
    'backup=s' => sub {
        my ($opt_name, $opt_value) = @_;
        $backupDir = realpath($opt_value);
    },
    'restore=s' => sub {
        my ($opt_name, $opt_value) = @_;
        $restoreDir = realpath($opt_value);
    },
    'help' => sub {pod2usage();}
    ) or pod2usage();

################################################################################
my $imagesSrcDir = "./docker-images";
my $saveDir = "./_images";
my @imagesToBuild = ("sw360empty", "couchdb-lucene", "sw360couchdb", "sw360nginx");
if($cveSearch) {
    push(@imagesToBuild, "cve-search-server");
}

################################################################################
chdir dirname(realpath($0));

if ("$^O" eq "darwin") { # setup tempdir for darwin
    my $tmpdir = "./_tmp";
    mkdir $tmpdir if ! -d $tmpdir;
    $ENV{TMPDIR} = realpath($tmpdir);
}

################################################################################
{ # docker
    my @dockerCmd = ("docker");
    my @dockerComposeCmd = ("docker-compose");

    if (-f "proxy.env") {
        my $addEnv = '';
        open my $in, "<:encoding(utf8)", "proxy.env" or die "proxy.env: $!";
        while (my $line = <$in>) {
            chomp $line;
            if ($line && ! ($line =~ m/#.*/)){
                unshift @dockerCmd, $line;
                unshift @dockerComposeCmd, $line;
                $addEnv = 1;
            }
        }
        close $in;
        if ($addEnv) {
            unshift @dockerCmd, "env";
            unshift @dockerComposeCmd, "env";
        }
    }

    if (system("docker info &> /dev/null") != 0) {
        print "INFO: add sudo to docker commands";
        unshift @dockerCmd, "sudo";
        unshift @dockerComposeCmd, "sudo";
    }

    sub dockerGen {
        my ($nonInteractive, @args) = @_;
        my @toCall = ();

        push(@toCall, @dockerCmd);
        push(@toCall, @args);

        if (! $nonInteractive) {
            0 == system(@toCall)
                or die "failed...";
            return "";
        } else {
            my @stdout = qx(@toCall);
            0 == ($? >> 8)
                or die "failed...";
            print @stdout;
            return @stdout;
        }
    }
    sub docker {
        dockerGen('', @_);
    }
    sub dockerRet {
        dockerGen(1, @_);
    }

    sub dockerComposeGen {
        my ($nonInteractive, @args) = @_;
        my @toCall = ();

        push(@toCall, @dockerComposeCmd);
        push(@toCall, "-f", "deployment/docker-compose.yml");
        if($cveSearch) {
            push(@toCall, "-f", "deployment/docker-compose.cve-search-server.yml");
        }
        if ($prod) {
            push(@toCall, "-f", "deployment/docker-compose.prod.yml");
        }else{
            mkdir "_deploy" if ! -d "_deploy";
            push(@toCall, "-f", "deployment/docker-compose.dev.yml");
            if($cveSearch) {
                push(@toCall, "-f", "deployment/docker-compose.dev.cve-search-server.yml");
            }
        }
        push(@toCall, @args);

        if (! $nonInteractive) {
            0 == system(@toCall)
                or die "failed...";
            return "";
        } else {
            my @stdout = qx(@toCall);
            0 == ($? >> 8)
                or die "failed...";
            print @stdout;
            return @stdout;
        }
    }
    sub dockerCompose {
        dockerComposeGen('', @_);
    }
    sub dockerComposeRet {
        dockerComposeGen(1, @_);
    }

    sub dockerBuild {
        my ($name, @args) = @_;
        @args = @args?@args:();

        if(defined $ENV{'SW360CHORES_VERSION'}){
            unshift @args, ("-t", "sw360/${name}:$ENV{'SW360CHORES_VERSION'}");
        }
        unshift @args, ("build", "-t", "sw360/$name", "--rm=true", "--force-rm=true");
        push @args, "$imagesSrcDir/$name/";

        print "INFO: docker build $name\n";
        docker(@args);
    }

    sub dockerRun {
        my ($name, @args) = @_;
        unshift @args, ("run", "-it", "sw360/$name");

        print "INFO: docker run $name\n";
        docker(@args);
    }

    sub dockerSave {
        my ($image) = @_;

        print "INFO: docker save $image\n";
        eval {
            docker(("save", "-o", "$saveDir/$image.tar", "$image"))
        }; warn $@ if $@;
    }

    sub dockerRmi {
        my ($image) = @_;

        print "INFO: docker rmi $image\n";
        eval {
            docker(("rmi", "$image"))
        }; warn $@ if $@;
    }

    sub dockerCp {
        my ($src_path, $dest_path) = @_;
        print "INFO: docker cp $src_path to $dest_path\n";
        docker(("cp", $src_path, $dest_path));
    }

    sub dockerGetNameOfImg {
        my ($imgId) = @_;
        chomp(my $imgTags = (dockerRet(("inspect", "--format='{{.RepoTags}}'", $imgId)))[0]);
        if ( $imgTags eq "[]" ) {
            return $imgId;
        }else{
            $imgTags =~ s%^\[%%g;
            $imgTags =~ s%:.*%%g;
            return $imgTags;
        }
    }
}

################################################################################
# handle images

sub prepareImage {
    my ($name) = @_;

    my $prepareScriptPl = "$imagesSrcDir/$name/prepare.pl";
    my $prepareScriptSh = "$imagesSrcDir/$name/prepare.sh";
    if (-x $prepareScriptPl) {
        do $prepareScriptPl;
    } elsif (-x $prepareScriptSh) {
        0 == system($prepareScriptSh)
            or die "failed to prepare $name";
    }
}

sub buildImage {
    my ($name) = @_;

    prepareImage $name;
    dockerBuild($name);
}

sub buildAllBase {
    foreach my $name (@imagesToBuild) {
        buildImage $name;
    }
}

sub buildPopulatedSW360 {
    sub copyWarsFromTo {
        my ($srcDir, $targetDir) = @_;

        my @wars = glob("$srcDir/*.war");
        remove_tree($targetDir) if -d $targetDir;
        mkdir $targetDir;
        for my $war (@wars) {
            copy($war, $targetDir);
        }
    }

    if (! "$cpWebappsDir" || ! -d "$cpWebappsDir") {
        die "please set webapps src folder via --webapps=/PATH/TO/WEBAPPS";
    }
    if (! "$cpDeployDir" || ! -d "$cpDeployDir") {
        die "please set deploy src folder via --deploy=/PATH/TO/DEPLOY";
    }

    my $sw360PopulatedDir = "$imagesSrcDir/sw360populated";

    copyWarsFromTo($cpWebappsDir, "$sw360PopulatedDir/_webapps");
    copyWarsFromTo($cpDeployDir, "$sw360PopulatedDir/_deploy");

    my @args = ();

    if(defined $ENV{'SW360_VERSION'}){
        unshift @args, ("-t", "sw360/sw360populated:$ENV{'SW360_VERSION'}");
    }

    buildImage("sw360populated",@args);
}

sub saveAll {
    mkdir "$saveDir" if (! -d "$saveDir");
    chomp(my @images = dockerComposeRet(("images", "-q")));

    mkdir "$saveDir/sw360" if (! -d "$saveDir/sw360");
    foreach my $imageId (@images) {
        dockerSave(dockerGetNameOfImg($imageId));
    }
}

################################################################################
# remove state and generated images
sub cleanupAll {
    eval {
        dockerCompose(("stop"));
    }; warn $@ if $@;
    chomp(my @images = dockerComposeRet(("images", "-q")));
    eval {
        dockerCompose(("down"));
    }; warn $@ if $@;
    foreach my $imageId (@images) {
        dockerRmi $imageId;
    }
}

################################################################################
# deploy wars via `docker cp`
sub copyToSW360Container {
    my ($srcDir, $targetDir) = @_;

    if ( -d $srcDir) {
        my @wars = glob("$srcDir/*.war");
        foreach my $war (@wars) {
            dockerCp($war, "sw360:$targetDir");
        }
    }
}

################################################################################
# backup and restore volumes
sub getContainerNameById {
    my ($containerId) = @_;
    chomp(my @containerName = dockerRet(("inspect", "-f",  "'{{ .Name }}'", $containerId)));
    my $containerName = $containerName[0];
    $containerName =~ s%^/%%g;
    return $containerName;
}

sub getListOfVolumes {
    my ($containerId) = @_;
    chomp(my @volumes = dockerRet(("inspect", "-f", "'{{ .Config.Volumes }}'", $containerId)));
    my $volumes = $volumes[0];

    $volumes =~ s%^map\[%%;
    $volumes =~ s%\]$%%;
    $volumes =~ s%:\{\}%%g;

    return split(' ', $volumes);
}

sub getBackupFileName {
    my ($containerName, $volume) = @_;
    my $backupFileName = $volume =~ s%/%_%gr;
    return "${containerName}_${backupFileName}.tar";
}

sub backupVolumes {
    sub backupVolumeOf {
        my ($containerId, $containerName, $volume) = @_;
        my $backupFileName = getBackupFileName($containerName, $volume);

        print "    backup volume $volume to $backupFileName\n";
        docker(("run", "--rm",
                "--volumes-from", $containerId,
                "-v", "$backupDir:/backup",
                "debian:jessie",
                "tar", "--one-file-system", "-cf", "/backup/$backupFileName", $volume));
    }

    sub backupAllVolumesOf {
        my ($containerId) = @_;
        my $containerName = getContainerNameById($containerId);
        my @volumes = getListOfVolumes($containerId);

        if (@volumes){
            print "backup container with id=$containerId and name=$containerName\n";

            foreach my $volume (@volumes) {
                backupVolumeOf($containerId, $containerName, $volume);
            }
        }
    }

    mkdir $backupDir if ! -d $backupDir;
    chomp(my @ids = dockerComposeRet(("ps", "-q")));
    foreach my $id (@ids) {
        backupAllVolumesOf($id);
    }
    exit 0;
}

sub restoreVolumes {
    sub restoreVolumeOf {
        my ($containerId, $containerName, $volume) = @_;
        my $backupFileName = getBackupFileName($containerName, $volume);

        if (-f "$restoreDir/$backupFileName"){
            local $| = 1; # activate autoflush to immediately show the prompt
            print "restore $backupFileName to $containerName? (y/N)\n";
            chomp(my $answer = <STDIN>);
            if (lc($answer) eq 'y') {
                print "restoring...\n";
                docker(("run", "--rm",
                        "--volumes-from", $containerId,
                        "-v", "$restoreDir:/backup",
                        "debian:jessie",
                        "tar", "-xf", "/backup/$backupFileName", "-C", "/"));
            }
        }
    }

    sub restoreAllVolumesOf {
        my ($containerId) = @_;
        my $containerName = getContainerNameById($containerId);
        my @volumes = getListOfVolumes($containerId);
        foreach my $volume (@volumes) {
            restoreVolumeOf($containerId, $containerName, $volume);
        }
    }

    if (! -d $restoreDir) {
        die "backupdir not found";
    }
    chomp(my @ids = dockerComposeRet(("ps", "-q")));
    foreach my $id (@ids) {
        restoreAllVolumesOf($id);
    }
    exit 0;
}

################################################################################
# actually do everything

backupVolumes() if $backupDir && !$restoreDir;

cleanupAll() if $cleanup;
buildAllBase() if $build;

restoreVolumes() if $restoreDir && !$backupDir;

if (! $prod) {
    copyToSW360Container($cpWebappsDir, "/opt/sw360/webapps") if $cpWebappsDir;
    copyToSW360Container($cpDeployDir, "/opt/sw360/deploy") if $cpDeployDir;
} else {
    buildPopulatedSW360() if $build;
}

saveAll() if $save;

if (defined $ARGV[0]) {
    dockerCompose(@ARGV);
}
