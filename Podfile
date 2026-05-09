platform :osx, '11.0'
use_frameworks!

target 'Clipy' do

  # Application
  pod 'PINCache'
  pod 'Sauce'
  pod 'Sparkle'
  pod 'RealmSwift'
  pod 'RxCocoa'
  pod 'RxSwift'
  pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
  pod 'KeyHolder'
  pod 'Magnet'
  pod 'RxScreeen'
  pod 'AEXML'
  pod 'LetsMove'
  pod 'SwiftHEXColors'
  # Utility
  pod 'BartyCrouch'
  pod 'SwiftLint'
  pod 'SwiftGen'

  target 'ClipyTests' do
    inherit! :search_paths

    pod 'Quick'
    pod 'Nimble'

  end

end

post_install do |installer|
  login_service_kit_path = File.join(
    installer.sandbox.root,
    'LoginServiceKit/Lib/LoginServiceKit/LoginServiceKit.swift'
  )
  if File.exist?(login_service_kit_path)
    File.chmod(0o644, login_service_kit_path)
    contents = File.read(login_service_kit_path)
    contents = contents.gsub(
      "let loginItemsListSnapshot: NSArray = LSSharedFileListCopySnapshot(loginItemList, nil).takeRetainedValue()\n        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return false }",
      "guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return false }\n        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()\n        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return false }"
    )
    contents = contents.gsub(
      "let loginItemsListSnapshot: NSArray = LSSharedFileListCopySnapshot(loginItemList, nil).takeRetainedValue()\n        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return nil }",
      "guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return nil }\n        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()\n        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return nil }"
    )
    File.write(login_service_kit_path, contents)
  end

  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.base_configuration_reference&.real_path&.tap do |path|
          next unless File.exist?(path)

          contents = File.read(path)
          File.write(path, contents.gsub('DT_TOOLCHAIN_DIR', 'TOOLCHAIN_DIR'))
        end
      end
    end
  end

  installer.pods_project.build_configurations.each do |config|
    config.build_settings['ARCHS'] = 'arm64'
    config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
