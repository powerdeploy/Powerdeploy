# Powerdeploy - Deceivingly Simple Deployments #

Powerdeploy is a lightweight application deployment tool built on [PowerShell][] that is simple enough to get up and running right away but powerful enough to deploy just about any application.

## So Simple ##

All you need to use Powerdeploy is the [module](Install-Powerdeploy-Module), an [application package][Deployment-Package] to deploy, and a target computer.

```
Invoke-Powerdeploy `
	-PackageArchive C:\MyPackages\MyPackage_3.2.3.zip `
	-Environment UAT `
	-ComputerName server01	
```

## Guiding Principles ##

If you have a team of people who can script installs and manage deployments, or high-end deployment orchestration tools, you probably have everything you need to continuously deploy your applications.  On the other hand, continuous deployment doesn't require expensive tools or complicated infrastructure.  

Whether you're trying to auto deploy an application for the first time or round out your arsenal of deployment processes and tools, Powerdeploy can help because it's:

* Simple to start with: Powerdeploy, at its foundation, provides a very narrow and specific set of functionality that makes it easy to get started without weeding through manuals or wading through videos.
* Extensible to grow with: Powerdeploy provides extensions, and extensibility that can make even complicated application deployments easy.
* Independent of other infrastructure and tools: Powerdeploy does not depend on other deployment workflow tools or installation frameworks.  It can be used on its own, from your workstation to deploy an application on demand, or in collaboration with workflow, continuous integration, and continuous deployment tools to provide application deployments in situations where rigorous processes are followed.  

## So Powerful ##

Check out [the documentation][wiki] for more information on how Powerdeploy does what it does and all of the ways it can do more.

## Building Powerdeploy ##

`git submodule update --init`

[PowerShell]: http://technet.microsoft.com/en-us/library/bb978526.aspx
[wiki]: https://github.com/powerdeploy/Powerdeploy/wiki
