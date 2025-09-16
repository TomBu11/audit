foreach ($property in $outTable.PSObject.Properties) {
  Action1-Set-CustomAttribute "$($property.Name)" "$($property.Value)"
}