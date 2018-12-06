$root = gi master:// -id "{3FB110C3-4034-4B45-9F4D-8EB1319C43AF}"
$items = $root | ls -r | ?{$_.TemplateName -eq "ApiSchedule"}

foreach($i in $items){

    $meetingName = $i.Name;
    Write-Host "Processing: $meetingName";
	$i | Remove-Item -r 
}
