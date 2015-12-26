#import "DDKeychain.h"

@implementation DDKeychain{
    

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Retrieves the password stored in the keychain for the HTTP server.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Identity:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method creates a new identity, and adds it to the keychain.
 * An identity is simply a certificate (public key and public information) along with a matching private key.
 * This method generates a new private key, and then uses the private key to generate a new self-signed certificate.
**/

static SecIdentityRef outIdentity = nil;
static SecTrustRef outTrust = nil;

OSStatus extractIdentityAndTrust(CFDataRef inPKCS12Data,
                                 SecIdentityRef *outIdentity,
                                 SecTrustRef *outTrust,
                                 CFStringRef keyPassword)
{
    OSStatus securityError = errSecSuccess;
    
    
    const void *keys[] =   { kSecImportExportPassphrase };
    const void *values[] = { keyPassword };
    CFDictionaryRef optionsDictionary = NULL;
    
    /* Create a dictionary containing the passphrase if one
     was specified.  Otherwise, create an empty dictionary. */
    optionsDictionary = CFDictionaryCreate(
                                           NULL, keys,
                                           values, (keyPassword ? 1 : 0),
                                           NULL, NULL);  // 1
    
    CFArrayRef items = NULL;
    securityError = SecPKCS12Import(inPKCS12Data,
                                    optionsDictionary,
                                    &items);                    // 2
    
    
    //
    if (securityError == 0) {                                   // 3
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust,
                                             kSecImportItemIdentity);
        CFRetain(tempIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        
        CFRetain(tempTrust);
        *outTrust = (SecTrustRef)tempTrust;
    }
    
    if (optionsDictionary)                                      // 4
        CFRelease(optionsDictionary);
    
    if (items)
        CFRelease(items);
    
    return securityError;
}

NSString* copySummaryString(SecIdentityRef identity)
{
    // Get the certificate from the identity.
    SecCertificateRef myReturnedCertificate = NULL;
    OSStatus status = SecIdentityCopyCertificate (identity,
                                                  &myReturnedCertificate);  // 1
    
    if (status) {
        NSLog(@"SecIdentityCopyCertificate failed.\n");
        return NULL;
    }
    
    CFStringRef certSummary = SecCertificateCopySubjectSummary
    (myReturnedCertificate);  // 2
    
    NSString* summaryString = [[NSString alloc]
                               initWithString:(__bridge NSString *)certSummary];  // 3
    
    CFRelease(certSummary);
    
    return summaryString;
}


+ (void)createNewIdentity 
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString * bundleCertPath = [basePath stringByAppendingPathComponent:@"cert/certificate.pfx"];
    NSData *certData = [NSData dataWithContentsOfFile:bundleCertPath];
    SecIdentityRef ident;
    SecTrustRef trust;
    if(extractIdentityAndTrust((__bridge CFDataRef)(certData), &ident, &trust, @"beameio#") == 0){
        outIdentity =ident;
    }
    NSString *identity = copySummaryString(ident);
    NSLog(@"Identiti %@", identity);
    
    
	
}

/**
 * Returns an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 * Currently this method is designed to return the identity created in the method above.
 * You will most likely alter this method to return a proper identity based on what it is you're trying to do.
**/
+ (NSArray *)SSLIdentityAndCertificates
{
	// Declare any Carbon variables we may create
	// We do this here so it's easier to compare to the bottom of this method where we release them all
	// Create array to hold the results
	NSMutableArray *result = [NSMutableArray array];
    if(outIdentity != nil){
        [result addObject:(__bridge id _Nonnull)(outIdentity)];
    }
	return result;

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Creates (if necessary) and returns a temporary directory for the application.
 *
 * A general temporary directory is provided for each user by the OS.
 * This prevents conflicts between the same application running on multiple user accounts.
 * We take this a step further by putting everything inside another subfolder, identified by our application name.
**/
+ (NSString *)applicationTemporaryDirectory
{
	NSString *userTempDir = NSTemporaryDirectory();
	NSString *appTempDir = [userTempDir stringByAppendingPathComponent:@"SecureHTTPServer"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:appTempDir] == NO)
	{
		[fileManager createDirectoryAtPath:appTempDir withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	return appTempDir;
}

/**
 * Simple utility class to convert a SecExternalFormat into a string suitable for printing/logging.
**/
//+ (NSString *)stringForSecExternalFormat:(SecExternalFormat)extFormat
//{
//	switch(extFormat)
//	{
//		case kSecFormatUnknown              : return @"kSecFormatUnknown";
//			
//		/* Asymmetric Key Formats */
//		case kSecFormatOpenSSL              : return @"kSecFormatOpenSSL";
//		case kSecFormatSSH                  : return @"kSecFormatSSH - Not Supported";
//		case kSecFormatBSAFE                : return @"kSecFormatBSAFE";
//			
//		/* Symmetric Key Formats */
//		case kSecFormatRawKey               : return @"kSecFormatRawKey";
//			
//		/* Formats for wrapped symmetric and private keys */
//		case kSecFormatWrappedPKCS8         : return @"kSecFormatWrappedPKCS8";
//		case kSecFormatWrappedOpenSSL       : return @"kSecFormatWrappedOpenSSL";
//		case kSecFormatWrappedSSH           : return @"kSecFormatWrappedSSH - Not Supported";
//		case kSecFormatWrappedLSH           : return @"kSecFormatWrappedLSH - Not Supported";
//			
//		/* Formats for certificates */
//		case kSecFormatX509Cert             : return @"kSecFormatX509Cert";
//			
//		/* Aggregate Types */
//		case kSecFormatPEMSequence          : return @"kSecFormatPEMSequence";
//		case kSecFormatPKCS7                : return @"kSecFormatPKCS7";
//		case kSecFormatPKCS12               : return @"kSecFormatPKCS12";
//		case kSecFormatNetscapeCertSequence : return @"kSecFormatNetscapeCertSequence";
//			
//		default                             : return @"Unknown";
//	}
//}

/**
 * Simple utility class to convert a SecExternalItemType into a string suitable for printing/logging.
**/
//+ (NSString *)stringForSecExternalItemType:(SecExternalItemType)itemType
//{
//	switch(itemType)
//	{
//		case kSecItemTypeUnknown     : return @"kSecItemTypeUnknown";
//			
//		case kSecItemTypePrivateKey  : return @"kSecItemTypePrivateKey";
//		case kSecItemTypePublicKey   : return @"kSecItemTypePublicKey";
//		case kSecItemTypeSessionKey  : return @"kSecItemTypeSessionKey";
//		case kSecItemTypeCertificate : return @"kSecItemTypeCertificate";
//		case kSecItemTypeAggregate   : return @"kSecItemTypeAggregate";
//		
//		default                      : return @"Unknown";
//	}
//}

/**
 * Simple utility class to convert a SecKeychainAttrType into a string suitable for printing/logging.
**/
//+ (NSString *)stringForSecKeychainAttrType:(SecKeychainAttrType)attrType
//{
//	switch(attrType)
//	{
//		case kSecCreationDateItemAttr       : return @"kSecCreationDateItemAttr";
//		case kSecModDateItemAttr            : return @"kSecModDateItemAttr";
//		case kSecDescriptionItemAttr        : return @"kSecDescriptionItemAttr";
//		case kSecCommentItemAttr            : return @"kSecCommentItemAttr";
//		case kSecCreatorItemAttr            : return @"kSecCreatorItemAttr";
//		case kSecTypeItemAttr               : return @"kSecTypeItemAttr";
//		case kSecScriptCodeItemAttr         : return @"kSecScriptCodeItemAttr";
//		case kSecLabelItemAttr              : return @"kSecLabelItemAttr";
//		case kSecInvisibleItemAttr          : return @"kSecInvisibleItemAttr";
//		case kSecNegativeItemAttr           : return @"kSecNegativeItemAttr";
//		case kSecCustomIconItemAttr         : return @"kSecCustomIconItemAttr";
//		case kSecAccountItemAttr            : return @"kSecAccountItemAttr";
//		case kSecServiceItemAttr            : return @"kSecServiceItemAttr";
//		case kSecGenericItemAttr            : return @"kSecGenericItemAttr";
//		case kSecSecurityDomainItemAttr     : return @"kSecSecurityDomainItemAttr";
//		case kSecServerItemAttr             : return @"kSecServerItemAttr";
//		case kSecAuthenticationTypeItemAttr : return @"kSecAuthenticationTypeItemAttr";
//		case kSecPortItemAttr               : return @"kSecPortItemAttr";
//		case kSecPathItemAttr               : return @"kSecPathItemAttr";
//		case kSecVolumeItemAttr             : return @"kSecVolumeItemAttr";
//		case kSecAddressItemAttr            : return @"kSecAddressItemAttr";
//		case kSecSignatureItemAttr          : return @"kSecSignatureItemAttr";
//		case kSecProtocolItemAttr           : return @"kSecProtocolItemAttr";
//		case kSecCertificateType            : return @"kSecCertificateType";
//		case kSecCertificateEncoding        : return @"kSecCertificateEncoding";
//		case kSecCrlType                    : return @"kSecCrlType";
//		case kSecCrlEncoding                : return @"kSecCrlEncoding";
//		case kSecAlias                      : return @"kSecAlias";
//		default                             : return @"Unknown";
//	}
//}

@end
