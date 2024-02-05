function ConvertTo-CaseInsensitiveHashtable {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]
        $Hashtable
    )
    $ciHashtable = [hashtable]::new([System.StringComparer]::InvariantCultureIgnoreCase)
    $Hashtable.Keys | ForEach-Object {
        $ciHashtable[$_] = $Hashtable[$_]
    }
    return $ciHashtable
}