function Get-PEArchitecture {
<#
.Synopsis

 PowerSploit Module - Get-PEArchitecture
 Author: Matthew Graeber (@mattifestation)
 License: BSD 3-Clause
 
.Description

 Get-PEArchitecture returns the architecture for which
 a Windows portable executable was compiled.
 
.Parameter Path

 Path to the executable.
 
.Example

 PS> Get-PEArchitecture C:\Windows\SysWOW64\calc.exe
 X86
 
.Example

 PS> Get-PEArchitecture C:\Windows\System32\cmd.exe
 X64
 
.Link

 My blog: http://www.exploit-monday.com
#>
    Param ( [Parameter(Position = 0, Mandatory = $True)] [String] $Path )

    if (!(Test-Path $Path)) {
        Write-Warning 'Invalid path or file does not exist.'
        return
    }
    
    # Parse PE header to see if binary was compiled 32 or 64-bit
    $FileStream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    
    [Byte[]] $MZHeader = New-Object Byte[](2)
    $FileStream.Read($MZHeader,0,2) | Out-Null
    
    $Header = [System.Text.AsciiEncoding]::ASCII.GetString($MZHeader)
    if ($Header -ne 'MZ') {
        Write-Warning 'Invalid PE header.'
        $FileStream.Close()
        return
    }
    
    # Seek to 0x3c - IMAGE_DOS_HEADER.e_lfanew (i.e. Offset to PE Header)
    $FileStream.Seek(0x3c, [System.IO.SeekOrigin]::Begin) | Out-Null
    
    [Byte[]] $lfanew = New-Object Byte[](4)
    
    # Read offset to the PE Header (will be read in reverse)
    $FileStream.Read($lfanew,0,4) | Out-Null
    $PEOffset = [Int] ('0x{0}' -f (( $lfanew[-1..-4] | % { $_.ToString('X2') } ) -join ''))
    
    # Seek to IMAGE_FILE_HEADER.IMAGE_FILE_MACHINE
    $FileStream.Seek($PEOffset + 4, [System.IO.SeekOrigin]::Begin) | Out-Null
    [Byte[]] $IMAGE_FILE_MACHINE = New-Object Byte[](2)
    
    # Read compiled architecture
    $FileStream.Read($IMAGE_FILE_MACHINE,0,2) | Out-Null
    $Architecture = '{0}' -f (( $IMAGE_FILE_MACHINE[-1..-2] | % { $_.ToString('X2') } ) -join '')
    $FileStream.Close()
    
    if (($Architecture -ne '014C') -and ($Architecture -ne '8664')) {
        Write-Warning 'Invalid PE header or unsupported architecture.'
        return
    }
    
    if ($Architecture -eq '014C') {
        return 'X86'
    } elseif ($Architecture -eq '8664') {
        return 'X64'
    } else {
        return 'OTHER'
    }

}
