# Cookbooks
Cookbooks for scripting LANSA Stacks

Azure [![Build status](https://dev.azure.com/VisualLansa/Lansa%20Azure%20Scalable%20License%20Images/_apis/build/status/Build%20Image%20Release%20Artefacts%203.0)](https://dev.azure.com/VisualLansa/Lansa%20Azure%20Scalable%20License%20Images/_build/latest?definitionId=48)

AWS [![Build status](https://dev.azure.com/VisualLansa/Lansa%20AWS%20Scalable%20License%20Images/_apis/build/status/Build%20Image%20Release%20Artefacts%203.0)](https://dev.azure.com/VisualLansa/Lansa%20AWS%20Scalable%20License%20Images/_build/latest?definitionId=59)

Cloudformation templates, shell scripts and Powershell scripts for launching Windows and Linux stacks in AWS & Microsoft Azure

There are two image types built by these scripts. The first is a complete installation of the Visual LANSA IDE and the second is a base image in which to deploy an MSI constructed by the Visual LANSA IDE - called the Scalable image.

Both image types are published in AWS Marketplace and Azure Marketplace.

There is also a CloudFormation template to instantiate a LANSA stack in which to host the LANSA MSI. This stack consists of a load balancer, 2 autoscaling groups, a SQL Server RDS instance and log files. This may suit any application which is installed using an MSI which uses SQL Server.

The Azure Resource Manager template is maintained in a separate repo
```git@github.com:robe070/azure-quickstart-templates.git```. Changes are submitted for pull request to ```git@github.com:Azure/azure-quickstart-templates.git```. Full instructions are here: http://www.evernote.com/l/AA2k2Nqi6UtA4YYx0k4_NIoyG8v8fLurcec/
### Usage
Requires the AWS Toolkit for Visual Studio to be installed.

Also requires Powershell tools for the pssproj projects, but they are not used. You can ignore if you wish. If not download is here…

https://visualstudiogallery.msdn.microsoft.com/c9eb3ba8-0c59-4944-9a62-6eee37294597/view/Discussions/1

I started with the Powershell tools for VS but found the Powershell ISE much better, especially as I needed to use the Powershell ISE in the Cloud instances I was baking. And in fact VS Code is better than that.

Clone the repo, of course!

The Scalable image is baked using `scripts/bake-scalable-ami.ps1`, and you can follow that through.

### Entrypoint scripts for baking

| Cloud | Platform | Type | Initial Bake | Update Bake | Status
| - | - | - | - | - | -
| AWS | Win2012 | IDE | bake-ide-ami-14-1-win2012.ps1 | Update-ide-ami.ps1 | Deprecated
| AWS | Win2016 | IDE | bake-ide-ami-14-1-win2016.ps1 | Update-ide-ami.ps1 | Deprecated
| AWS | Win2012 | Scalable | bake-scalable-ami-14-1-win2012.ps1 | none | Live
| AWS | Win2016 | Scalable | bake-scalable-ami-14-2-win2016.ps1 | none | On Hold
| Azure | Win2012 | IDE | bake-ide-azure-14-1.ps1 | Update-ide-azure.ps1 | Deprecated
| Azure | Win2012 | Scalable | bake-scalable-azure-14-0.ps1 | none | Live

The Update scripts are designed to build all images for the Cloud and Type in one script as hands free as possible using the last image created to create the next image.

To update the IDE images, add the EPCs to the Cloud image e.g. "\\\\devsrv\ReleasedBuilds\v14\CloudOnly\SPIN0334\_LanDVDcut\_L4W14100_4138_160727_EPC1410xx" and in the script update the VersionText (and AmazonAMIName for Azure) and press F5. AWS will not prompt at all. Azure needs hand holding. Note that the jdk8 install prompt may be conditioned on ```-not $update``` the next time an update is required as its now been installed with the latest update to the Azure IDE image - EPC 141050.

Scalable updates are rare and are just to keep the base software up to date, including Windows Updates.

For the LANSA Stack open the VS solution CloudFormation/CloudFormation.sln, and start with `CloudFormationWindows/lansa-master-win.cfn.template`

##### Note: I would suggest you don't use the outlining feature in the template files. The format is not easy to read, and breaks our coding standards too!

A fundamental issue was which instance was responsible for database updates? We start up an autoscaling group with a single web server which is the one that applies table changes and the like. The rest of the web servers are truly scalable in a separate autoscaling group. The MSI has a switch to apply DB updates or not.

You may start with our stack and replace install-lansa-ide.ps1 with install-myapp.ps1. At least to get started? That would be an awesome first step if its got legs for your requirements! If the dual ASG model is required by you then off you go!

The maintenance of the web servers is performed in the nested stack - webserver-win.cfn.template – one call for the DB webserver and one for the rest. Notice `configSets`. `icing-install` is the config which is run at launch . The `userdata` just contains a call to `cfn-init.exe` which calls the `icing-install` `configset` which then eventually calls `install-lansa-msi.ps1` (part of the configset is to download the MSI from S3)

There are triggers provided in the web server template to allow maintenance operations like upgrading the MSI, or running Windows Updates.
