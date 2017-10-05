configuration InstallHyperV 
{ 

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost
    {
            WindowsFeature HyperV 
        { 
            Ensure = "Present" 
            Name = "Hyper-V"		
        }

        LocalConfigurationManager 
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
   }
} 