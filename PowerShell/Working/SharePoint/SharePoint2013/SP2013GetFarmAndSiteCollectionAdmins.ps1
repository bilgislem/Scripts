## SharePoint Server: PowerShell Script to report on all Farm Administrators and Site Collection Administrators across a Farm ##

## Overview: PowerShell Script that produces an XML report on all Farm Administrators and Site Collection Administrators

## Environments: SharePoint Server 2010 / 2013 Farms

## Resource: http://gallery.technet.microsoft.com/office/PowerShell-Script-for-aeba93d8

#Add SharePoint PowerShell SnapIn if not already added 
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { 
    Add-PSSnapin "Microsoft.SharePoint.PowerShell" 
} 

function Get-SPWeb([string]$url) {
 $SPSite = Get-SPSite $url
 return $SPSite.OpenWeb()
 $SPSite.Dispose()
}


function Get-SPWebApplications{
$SPWebApplicationCollection = Get-SPWebApplication -IncludeCentralAdministration
return $SPWebApplicationCollection
}


function Get-SPAdminWebApplication {
 $SPWebApplicationCollection = Get-SPWebApplications
   foreach ($SPWebApplication in $SPWebApplicationCollection) {
     if ($SPWebApplication.IsAdministrationWebApplication) {
      $adminWebapp = $SPWebApplication
     }
 }
 return $adminWebApp
}
function Get-SPfarmAdministrators {
  $admin = Get-SPAdminWebApplication
  foreach ($adminsite in $admin.Sites ) {
    $adminWeb = Get-SPweb($adminsite.url)
    $AdminGroupName = $adminWeb.AssociatedOwnerGroup
    $farmAdministratorsGroup = $adminweb.SiteGroups[$AdminGroupName]
    return $farmAdministratorsGroup.users
  }
}

function Get-ALLSiteCollectionAdminstrators{

$spWebApps = Get-SPWebApplications
 foreach ($spWebApp in $spWebApps)
{

#WEB APPLICATION ENTITY
$WebAppElem= $resultInXml.CreateElement("WebApplication")
$WebAppElem.SetAttribute("Url", $spWebApp.Url);
$WebAppsElem.AppendChild($WebAppElem);

#SITE COLLECTIONS ENTITY
$SiteCollsElem= $resultInXml.CreateElement("SiteCollections")
$WebAppElem.AppendChild($SiteCollsElem);

    foreach($site in $spWebApp.Sites)
    {

#SITE COLLECTION ENTITY
$SiteCollElem= $resultInXml.CreateElement("SiteCollection")
$SiteCollElem.SetAttribute("Url", $site.Url);
$SiteCollsElem.AppendChild($SiteCollElem);   

#SITE COLLECTION ADMINISTRATORS ENTITY
$SiteCollAdmsElem= $resultInXml.CreateElement("SiteCollectionAdministrators")
$SiteCollElem.AppendChild($SiteCollAdmsElem);   
    
        foreach($siteAdmin in $site.RootWeb.SiteAdministrators)
        {
#SITE COLLECTION ADMINISTRATOR ENTITY
$SiteCollAdmElem= $resultInXml.CreateElement("SiteCollectionAdministrator")
$SiteCollAdmElem.SetAttribute("UserLogin",$siteAdmin.UserLogin)
$SiteCollAdmElem.SetAttribute("DisplayName",$siteAdmin.DisplayName)
$SiteCollAdmsElem.AppendChild($SiteCollAdmElem); 
#            Write-Host "$($siteAdmin.ParentWeb.Url) - $($siteAdmin.DisplayName)"
        }
        $site.Dispose()
    }
        
 }

}

####################
#  MAIN
####################

$xmlPath = "$((pwd).path)/SPAdministratorsReport.xml";

$SPfarm = [Microsoft.SharePoint.Administration.SPFarm]::get_Local()

$resultInXml = new-object xml
$decl = $resultInXml.CreateXmlDeclaration("1.0", $null, $null)
$rootNode = $resultInXml.CreateElement("AdministratorsReport");
$resultInXml.InsertBefore($decl, $resultInXml.DocumentElement)
$resultInXml.AppendChild($rootNode);

 #FARM ENTITY
$farmElem = $resultInXml.CreateElement("Farm")
$farmElem.SetAttribute("ID", $SPfarm.Id );
$rootNode.AppendChild($farmElem);

#FARM ADMINISTRATORS ENTITY
$farmAdminsElem= $resultInXml.CreateElement("FarmAdministrators")
$farmElem.AppendChild($farmAdminsElem);


$farmAdmins = Get-SPfarmAdministrators

foreach ($farmAdmin in $farmAdmins)
{
$farmAdminElem = $resultInXml.CreateElement("FarmAdmin")
$farmAdminElem.SetAttribute("UserLogin",$farmAdmin.UserLogin)
$farmAdminElem.SetAttribute("DisplayName",$farmAdmin.DisplayName)
$farmAdminsElem.AppendChild($farmAdminElem);
}

#WEB APPLICATIONS ENTITY
$WebAppsElem= $resultInXml.CreateElement("WebApplications")
$farmElem.AppendChild($WebAppsElem);

#WEB APPLICATION ENTITY
Get-ALLSiteCollectionAdminstrators

#Output

$resultInXml.Save($xmlPath)

