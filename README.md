# Re-sign an iOS app

1. Go to <https://developer.apple.com/account/ios/certificate/distribution> and create a distribution certificate.

2. Download the distribution certificate and install it into your computer's keychain.

3. Go to <https://developer.apple.com/account/ios/identifier/bundle> and create an app bundle ID.

4. Go to <https://developer.apple.com/account/ios/profile/production> and create a distribution provisioning profile. The provisioning profile should use the app ID and distribution certificate that you created in the previous steps.

5. Download the distribution provisioning profile and put it in a location where you can find it.

6. Go to <https://itunesconnect.apple.com/> and create an iOS app with the same bundle ID that you created earlier.

7. Run the following command:

       $ security find-identity -v -p codesigning

8. Copy the signature of the distribution certificate that you installed earlier.

9. Re-sign the app:

       $ bash resign.sh -s /Users/myname/my.ipa -c "88C2CxxxCAFA58" -p myprovisioningprofile.mobileprovision -i 'my.bundle.id'

10. Start Xcode.

11. Open Application Loader by clicking Xcode > Open Developer Tools > Application Loader.

12. Press the Deliver Your App button and upload your re-signed ipa, which has the name my-resigned.ipa.

