#Update the ID to match the parent item that is a good searching point for children that need updating
$root = gi master:// -id "{2B9B79C1-C6E1-47CC-83FF-55466149548C}"

# Now lookup all children items that match the template your looking for
$items = $root | ls -r | ?{$_.TemplateName -eq "meeting"}

# Load up a hierarchy of some references to the Renderings that your going to add to the page
$legacyRow = gi "master:\sitecore\layout\Renderings\Project\Common\Section Columns\Row Legacy" | New-Rendering -Placeholder "page-body-meeting" 
$heading = gi master:\sitecore\layout\Renderings\Feature\PageContent\Blocks\Text\Heading | New-Rendering -Placeholder "/page-body-meeting/row-heading" -Parameter @{"IsAppleWatchTitle"=1; }
$twoColumn = gi "master:\sitecore\layout\Renderings\Project\Common\Section Columns\2 Column 6-6" | New-Rendering -Placeholder "/page-body-meeting/row" -Parameter @{"IsAppleWatch2Column"=1; }
$oneColumn = gi "master:\sitecore\layout\Renderings\Project\Common\Section Columns\1 Column" | New-Rendering -Placeholder "/page-body-meeting/row" -Parameter @{"IsAppleWatch1Column"=1; }
$simpleImage = gi "master:\sitecore\layout\Renderings\Feature\Media\Image\Simple Image" | New-Rendering -Placeholder "/page-body-meeting/row_x/col-wide_x" -Parameter @{"IsAppleWatch1ColumnSimpleImage"=1; }
$richText = gi "master:\sitecore\layout\Renderings\Feature\PageContent\Blocks\Text\Rich Text Block" | New-Rendering -Placeholder "/page-body-meeting/row_x/col-wide_x" -Parameter @{"IsAppleWatch1ColumnRichText"=1; }

# Load up the hierarchy of the data-sources that will be needed by your content blocks
$headingPath = "/sitecore/content/ClientWebsite/Content Modules/Campaign/Apple Watch/Apple Watch title"
$imagePath = "/sitecore/content/ClientWebsite/Content Modules/Campaign/Apple Watch/Apple Watch image"
$offerPath = "/sitecore/content/ClientWebsite/Content Modules/Campaign/Apple Watch/Apple Watch Offer"

# Function to convert Dynamic Placeholder IDs to short guids
function ShortGuid($gid)
{
    $rowId = $gid.UniqueId -Replace "}", ""
    $rowId = ($rowId -Replace "{", "").ToLower()
    return $rowId;
}

foreach($i in $items){
	
	# Create a new version of the child item, so that this can all be rolled back (Works in Sitecore 8 +). Prentation Details were not versioned before Sitecore 8.
    $newmeetingVersion = Add-ItemVersion -Path $i.Paths.Path -IfExist Append -Language "en"
	
	# Add the Rendering container component (row) to our new Item Version.
	# Add it to the Final Layout (-FinalLayout)
	# Add it at a particular position between renderings already added to the page (-Index 51)
	# Give this rendering a parameter (IsAppleWatch) So that we can easily look it up in powershell to get the correct UniqueId once its added. You will need this UniqueId for the dynamic placeholders #    within the Row
    Add-Rendering -Item $newmeetingVersion -Rendering $legacyRow -Placeholder "page-body-meeting" -FinalLayout -Parameter @{"IsAppleWatch"=1; "Background"="{8E8F7EC6-4B51-4E32-B448-43F354A03EEF}"; } -Index 51
	
	# Lookup the Rendering that we just added matching it to the Parameter
    $renderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder "page-body-meeting" -Parameter @{"IsAppleWatch"=1; }
    
	# This is a quick test to ensure the rendering instance is valid
    if ($renderingInstance) { 
	
		# lookup the UniqueId in short GUID format
        $rowId = ShortGuid($renderingInstance)
        Write-Host "retrieved ID for outer row is: $rowId";
	   
		#Add the heading into dynamic placholder for headings within the row
		$newHeadingPlaceholder = "/page-body-meeting/row-heading_$rowId"
		Add-Rendering -Item $newmeetingVersion -Rendering $heading -Placeholder $newHeadingPlaceholder -Datasource $headingPath -FinalLayout -Parameter @{"IsAppleWatchTitle"=1; } 
		Write-Host "Added in the heading";
		
		#Add the two column rendering in the dynamic placholder for the row body
		$new2ColumnPlaceholder = "/page-body-meeting/row_$rowId"
		Add-Rendering -Item $newmeetingVersion -Rendering $twoColumn -Placeholder $new2ColumnPlaceholder -FinalLayout -Parameter @{"IsAppleWatch2Column"=1; }
		$twoColumnRenderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder $new2ColumnPlaceholder -Parameter @{"IsAppleWatch2Column"=1; }
		# Lookup the unique ID for the two column rendering so that other renderings can be added within
		$twoColumnRenderingId = ShortGuid($twoColumnRenderingInstance)
		Write-Host "Added in the two column";
				
		#Add the simple image into the left hand side of the two column component
		$colWidePlaceholder = "/page-body-meeting/row_$rowId/col-wide_$twoColumnRenderingId"
		Add-Rendering -Item $newmeetingVersion -Rendering $simpleImage -Placeholder $colWidePlaceholder -FinalLayout -Parameter @{"IsAppleWatch1ColumnSimpleImage"=1; } -Datasource $imagePath
		$imageRenderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder $colWidePlaceholder -Parameter @{"IsAppleWatch1ColumnSimpleImage"=1; }
		Write-Host "Added the image";
		
		#Add the Rich Text component and datasource into the right hand side of the two column component
		$colWidePlaceholderRight = "/page-body-meeting/row_$rowId/col-wide_$($twoColumnRenderingId)_1"
		Add-Rendering -Item $newmeetingVersion -Rendering $richText -Placeholder $colWidePlaceholderRight -FinalLayout -Parameter @{"IsAppleWatch1ColumnRichText"=1; } -Datasource $offerPath
		$textRenderingInstance = Get-Rendering -Item $newmeetingVersion -FinalLayout -Placeholder $colWidePlaceholderRight -Parameter @{"IsAppleWatch1ColumnRichText"=1; }

		Write-Host "Finished adding promotion to the meeting";
    } else
    {
        Write-Host "Could not load renderingInstance $rowId";
    }      
}


