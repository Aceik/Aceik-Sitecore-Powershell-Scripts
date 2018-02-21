$root = gi master:// -id "{46973BFF-DEE9-472B-A247-ECB9CFCD2490}"
$items = $root | ls -r | ?{$_.TemplateName -eq "meeting"}
$legacyRow = gi "master:\sitecore\layout\Renderings\Project\Common\Section Columns\Row Legacy" | New-Rendering -Placeholder "page-body-meeting" 
$heading = gi master:\sitecore\layout\Renderings\Feature\PageContent\Blocks\Text\Heading | New-Rendering -Placeholder "/page-body-meeting/row-heading" -Parameter @{"IsAppleWatchTitle"=1; }

$twoColumn = gi "master:\sitecore\layout\Renderings\Project\Common\Section Columns\2 Column 6-6" | New-Rendering -Placeholder "/page-body-meeting/row" -Parameter @{"IsAppleWatch2Column"=1; }
$oneColumn = gi "master:\sitecore\layout\Renderings\Project\Common\Section Columns\1 Column" | New-Rendering -Placeholder "/page-body-meeting/row" -Parameter @{"IsAppleWatch1Column"=1; }

$simpleImage = gi "master:\sitecore\layout\Renderings\Feature\Media\Image\Simple Image" | New-Rendering -Placeholder "/page-body-meeting/row_x/col-wide_x" -Parameter @{"IsAppleWatch1ColumnSimpleImage"=1; }
$richText = gi "master:\sitecore\layout\Renderings\Feature\PageContent\Blocks\Text\Rich Text Block" | New-Rendering -Placeholder "/page-body-meeting/row_x/col-wide_x" -Parameter @{"IsAppleWatch1ColumnRichText"=1; }

$headingPath = "/sitecore/content/ClientWebsite/Content Modules/Campaign/Apple Watch/Apple Watch title"
$imagePath = "/sitecore/content/ClientWebsite/Content Modules/Campaign/Apple Watch/Apple Watch image"
$offerPath = "/sitecore/content/ClientWebsite/Content Modules/Campaign/Apple Watch/Apple Watch Offer"

function ShortGuid($gid)
{
    $rowId = $gid.UniqueId -Replace "}", ""
    $rowId = ($rowId -Replace "{", "").ToLower()
    return $rowId;
}

foreach($i in $items){

    $meetingName = $i.Name;
    Write-Host "Processing: $meetingName";
    
    $newmeetingVersion = Add-ItemVersion -Path $i.Paths.Path -IfExist Append -Language "en"
    
    $matchingRows = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder "page-body-meeting"
    if($matchingRows)
    {
        $myIndex = $matchingRows.Length;
        Write-Host "Index is based on $myIndex";
        
        $newmeetingVersion = Add-ItemVersion -Path $i.Paths.Path -IfExist Append -Language "en"
        
        #Gather a list of existing components on the Final Renderings
        $finalLayoutField = $newmeetingVersion.Fields[[Sitecore.FieldIDs]::FinalLayoutField]
        $finalLayoutXml = [Sitecore.Data.Fields.LayoutField]::GetFieldValue($finalLayoutField)
        $finalLayout = [Sitecore.Layouts.LayoutDefinition]::Parse($finalLayoutXml)
        $maxIndex = $finalLayout.Devices[0].Renderings.Count
        $allRenderings = $finalLayout.Devices[0].Renderings
        
        # Find a list of existing Row renderings
        #$existingRowRenderings = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder "page-body-meeting"
        # Default the insert index to 10
        $indexToInsert = 10
        
        $firstIndexMatchFound = false
        # loop over the existing rows and find where in the renderings list it exists
        foreach($existingRow in $matchingRows)
        {
            if(!$firstIndexMatchFound)
            {
                $uid = ShortGuid($existingRow)
                #Write-Host "existing rown UniqueId $uid";
                $insideIndex = 0
                foreach($comparableRendering in $allRenderings)
                {
                    if(!$firstIndexMatchFound)
                    {
                        $cuid = ShortGuid($comparableRendering)
                        #Write-Host "comparableRendering rown UniqueId $cuid";
                        if($uid.equals($cuid))
                        {
                            Write-Host "Found a match at Index $insideIndex $uid $cuid";
                            $indexToInsert = $insideIndex + 1
                            $firstIndexMatchFound = true
                            continue
                        }
                        $insideIndex++
                    }#end inner if $firstIndexMatchFound
                }#end inner foreach
            }#end if $firstIndexMatchFound
        }#end outer foreach
        Write-Host "The promotion will be inserted at $indexToInsert";
        
        #Begin inserting the promotion
        Add-Rendering -Item $newmeetingVersion -Rendering $legacyRow -Placeholder "page-body-meeting" -FinalLayout -Parameter @{"IsAppleWatch"=1; "Background"="{8E8F7EC6-4B51-4E32-B448-43F354A03EEF}"; } -Index $indexToInsert
        $renderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder "page-body-meeting" -Parameter @{"IsAppleWatch"=1; }
        
        if ($renderingInstance) { 
           $rowId = ShortGuid($renderingInstance)
           Write-Host "retrieved ID for outer row is: $rowId";
        } else
        {
            Write-Host "Lost renderingInstance $rowId";
        }
        
        #Write-Host "The original is: $rowId";
        
        $newHeadingPlaceholder = "/page-body-meeting/row-heading_$rowId"
        
        #Add the heading in
        Add-Rendering -Item $newmeetingVersion -Rendering $heading -Placeholder $newHeadingPlaceholder -Datasource $headingPath -FinalLayout -Parameter @{"IsAppleWatchTitle"=1; } 
        # Background={69595547-7BB7-45F5-AD19-F8D9A996F73A}
        Write-Host "Added in the title";
        
        #Add the two column in
        $new2ColumnPlaceholder = "/page-body-meeting/row_$rowId"
        Add-Rendering -Item $newmeetingVersion -Rendering $twoColumn -Placeholder $new2ColumnPlaceholder -FinalLayout -Parameter @{"IsAppleWatch2Column"=1; }
        $twoColumnRenderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder $new2ColumnPlaceholder -Parameter @{"IsAppleWatch2Column"=1; }
        $twoColumnRenderingId = ShortGuid($twoColumnRenderingInstance)
        Write-Host "Added in the two column";
                
        #Add the simple image in
        $colWidePlaceholder = "/page-body-meeting/row_$rowId/col-wide_$twoColumnRenderingId"
        Add-Rendering -Item $newmeetingVersion -Rendering $simpleImage -Placeholder $colWidePlaceholder -FinalLayout -Parameter @{"IsAppleWatch1ColumnSimpleImage"=1; } -Datasource $imagePath
        $imageRenderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder $colWidePlaceholder -Parameter @{"IsAppleWatch1ColumnSimpleImage"=1; }
        Write-Host "Added the image";
        
        #Add in the rich Text
        $colWidePlaceholderRight = "/page-body-meeting/row_$rowId/col-wide_$($twoColumnRenderingId)_1"
        
        Add-Rendering -Item $newmeetingVersion -Rendering $richText -Placeholder $colWidePlaceholderRight -FinalLayout -Parameter @{"IsAppleWatch1ColumnRichText"=1; } -Datasource $offerPath
        $textRenderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder $colWidePlaceholderRight -Parameter @{"IsAppleWatch1ColumnRichText"=1; }
        Write-Host "Offer placeholder: $colWidePlaceholderRight";
        Write-Host "Finished adding promotion to the meeting";
    }
    
}


