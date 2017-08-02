
$ConfigurationName = 'Release'
$Code_Sign = 'iPhone Distribution: xxx xxx (xxxxxxxxxx)'
$Project_Path = '~/xxx/xxx.xcodeproj'
$BundleID = 'com.xxx.xxx'
$ProjectName = 'ProjectName'
$TeamName ='xxxxxxxxxx'


if ARGV[0]
    $ConfigurationName = ARGV[0]
end
if ARGV[1]
    $Code_Sign = ARGV[1]
end
if ARGV[2]
    $ProjectName = ARGV[2]
end
if ARGV[3]
    $Project_Path = ARGV[3] + '/' + $ProjectName + '.xcodeproj'
end
if ARGV[4]
    $TeamName = ARGV[4]
end
if ARGV[5]
    $BundleID = ARGV[5]
end


puts ARGV

require 'xcodeproj'
project = Xcodeproj::Project.open($Project_Path)


#project sign provison manual
project.root_object.attributes['TargetAttributes'].each do |targetUUID|
    targetUUID.each do |curUUID|
        if curUUID['ProvisioningStyle']
            curUUID['ProvisioningStyle'] = 'Manual'
        end
        if curUUID['DevelopmentTeam']
            curUUID['DevelopmentTeam'] = $TeamName
        end
    end
end



project.targets.each do |target|
    
    $CurrentBundleID = $BundleID
    $CurrentProvisioning = ''
    if target.name != $ProjectName
        $CurrentBundleID = $BundleID + "." + target.name
    end
    
    case $BundleID
        when "com.xxxx.xxxx"
           case target.name
              when "ProjectName"
              $CurrentProvisioning = 'XXXX Distribution'
              when "NotificationService"
              $CurrentProvisioning = 'Notification Service Distribution'
              else
              $CurrentProvisioning = 'XXXX Distribution'
           end
           
        when "com.xxx.xxx"
          case target.name
              when "ProjectName"
              $CurrentProvisioning = 'xxx Distribution'
              when "NotificationService"
              $CurrentProvisioning = 'xxx NotificationService'
              else
              $CurrentProvisioning = 'xxx Distribution'
          end
          
    end
    
    puts "bundleId=" + $CurrentBundleID + " provisioning=" + $CurrentProvisioning
  
    
    target.build_configurations.each do |config|
        if config.name == $ConfigurationName
            config.build_settings['CODE_SIGN_IDENTITY'] = $Code_Sign
            config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'iPhone Distribution'
            config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = $CurrentBundleID
            config.build_settings['DEVELOPMENT_TEAM'] = $TeamName
            config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = $CurrentProvisioning
        end
        
    end
end

project.save

