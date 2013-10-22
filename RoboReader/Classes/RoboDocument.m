//
//	RoboDocument.m
//	Robo v2.5.4
//
//	Copyright © 2011-2012 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "RoboDocument.h"
#import "CGPDFDocument.h"

@implementation RoboDocument

@synthesize guid = _guid;
@synthesize fileDate = _fileDate;
@synthesize fileSize = _fileSize;
@synthesize pageCount = _pageCount;
@synthesize currentPage = _currentPage;
@synthesize bookmarks = _bookmarks;
@synthesize lastOpen = _lastOpen;
@synthesize password = _password;
@dynamic fileName, fileURL;


+ (NSString *)GUID {


    CFUUIDRef theUUID;
    CFStringRef theString;

    theUUID = CFUUIDCreate(NULL);

    theString = CFUUIDCreateString(NULL, theUUID);

    NSString *unique = [NSString stringWithString:(__bridge id) theString];

    CFRelease(theString);
    CFRelease(theUUID); // Cleanup

    return unique;
}

+ (NSString *)applicationPath {


    NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    return [documentsPaths[0] stringByDeletingLastPathComponent]; // Strip "Documents" component
}

+ (NSString *)applicationSupportPath {


    NSFileManager *fileManager = [NSFileManager new]; // File manager instance

    NSURL *pathURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];

    return [pathURL path]; // Path to the application's "~/Library/Application Support" directory
}

+ (NSString *)relativeFilePath:(NSString *)fullFilePath {


    assert(fullFilePath != nil); // Ensure that the full file path is not nil

    NSString *applicationPath = [RoboDocument applicationPath]; // Get the application path

    NSRange range = [fullFilePath rangeOfString:applicationPath]; // Look for the application path

    assert(range.location != NSNotFound); // Ensure that the application path is in the full file path

    return [fullFilePath stringByReplacingCharactersInRange:range withString:@""]; // Strip it out
}

+ (NSString *)archiveFilePath:(NSString *)filename {


    assert(filename != nil); // Ensure that the archive file name is not nil

    //NSString *archivePath = [RoboDocument documentsPath]; // Application's "~/Documents" path

    NSString *archivePath = [RoboDocument applicationSupportPath]; // Application's "~/Library/Application Support" path

    NSString *archiveName = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];

    return [archivePath stringByAppendingPathComponent:archiveName]; // "{archivePath}/'filename'.plist"
}

+ (RoboDocument *)unarchiveFromFileName:(NSString *)filename password:(NSString *)phrase {


    RoboDocument *document = nil; // RoboDocument object

    NSString *withName = [filename lastPathComponent]; // File name only

    NSString *archiveFilePath = [RoboDocument archiveFilePath:withName];

    @try // Unarchive an archived RoboDocument object from its property list
    {
        document = [NSKeyedUnarchiver unarchiveObjectWithFile:archiveFilePath];

        if ((document != nil) && (phrase != nil)) // Set the document password
        {
            [document setValue:[phrase copy] forKey:@"password"];
        }
    }
    @catch (NSException *exception) // Exception handling (just in case O_o)
    {
#ifdef DEBUG
        NSLog(@"%s Caught %@: %@", __FUNCTION__, [exception name], [exception reason]);
#endif
    }

    return document;
}

+ (RoboDocument *)withDocumentFilePath:(NSString *)filePath password:(NSString *)phrase {


    RoboDocument *document = nil; // RoboDocument object

    document = [RoboDocument unarchiveFromFileName:filePath password:phrase];

    if (document == nil) // Unarchive failed so we create a new RoboDocument object
    {
        document = [[RoboDocument alloc] initWithFilePath:filePath password:phrase];
    }

    return document;
}

+ (BOOL)isPDF:(NSString *)filePath {


    BOOL state = NO;

    if (filePath != nil) // Must have a file path
    {
        const char *path = [filePath fileSystemRepresentation];

        int fd = open(path, O_RDONLY); // Open the file

        if (fd > 0) // We have a valid file descriptor
        {
            const unsigned char sig[4]; // File signature

            ssize_t len = read(fd, (void *) &sig, sizeof(sig));

            if (len == 4) if (sig[0] == '%') if (sig[1] == 'P') if (sig[2] == 'D') if (sig[3] == 'F')
                state = YES;

            close(fd); // Close the file
        }
    }

    return state;
}


- (id)initWithFilePath:(NSString *)fullFilePath password:(NSString *)phrase {


    id object = nil; // RoboDocument object

    if ([RoboDocument isPDF:fullFilePath] == YES) // File must exist
    {
        if ((self = [super init])) // Initialize the superclass object first
        {
            _guid = [RoboDocument GUID]; // Create a document GUID

            _password = [phrase copy]; // Keep a copy of any document password

            _bookmarks = [NSMutableIndexSet new]; // Bookmarked pages index set

            _currentPage = @1; // Start page 1

            _fileName = [RoboDocument relativeFilePath:fullFilePath];

            CFURLRef docURLRef = (__bridge CFURLRef) [self fileURL]; // CFURLRef from NSURL

            CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateX(docURLRef, _password);

            if (thePDFDocRef != NULL) // Get the number of pages in a document
            {
                int pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef);

                _pageCount = @(pageCount);

                CGPDFDocumentRelease(thePDFDocRef); // Cleanup
            }
            else // Cupertino, we have a problem with the document
            {
                NSAssert(NO, @"CGPDFDocumentRef == NULL");
            }

            NSFileManager *fileManager = [NSFileManager new]; // File manager

            _lastOpen = [NSDate dateWithTimeIntervalSinceReferenceDate:0.0]; // Last opened

            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:fullFilePath error:NULL];

            _fileDate = fileAttributes[NSFileModificationDate]; // File date

            _fileSize = fileAttributes[NSFileSize]; // File size (bytes)

            [self saveRoboDocument]; // Save RoboDocument object

            object = self; // Return initialized RoboDocument object
        }
    }

    return object;
}

- (void)dealloc {


    _fileURL = nil;


    _fileName = nil;


}

- (NSString *)fileName {


    return [_fileName lastPathComponent];
}

- (NSURL *)fileURL {


    if (_fileURL == nil) // Create and keep the file URL the first time it is requested
    {
        NSString *fullFilePath = [[RoboDocument applicationPath] stringByAppendingPathComponent:_fileName];

        _fileURL = [[NSURL alloc] initFileURLWithPath:fullFilePath isDirectory:NO]; // File URL from full file path
    }

    return _fileURL;
}

- (BOOL)archiveWithFileName:(NSString *)filename {


    NSString *archiveFilePath = [RoboDocument archiveFilePath:filename];

    return [NSKeyedArchiver archiveRootObject:self toFile:archiveFilePath];
}

- (void)saveRoboDocument {


    [self archiveWithFileName:[self fileName]];
}

- (void)updateProperties {

}


- (void)encodeWithCoder:(NSCoder *)encoder {


    [encoder encodeObject:_guid forKey:@"FileGUID"];

    [encoder encodeObject:_fileName forKey:@"FileName"];

    [encoder encodeObject:_fileDate forKey:@"FileDate"];

    [encoder encodeObject:_pageCount forKey:@"PageCount"];

    [encoder encodeObject:_currentPage forKey:@"PageNumber"];

    [encoder encodeObject:_bookmarks forKey:@"Bookmarks"];

    [encoder encodeObject:_fileSize forKey:@"FileSize"];

    [encoder encodeObject:_lastOpen forKey:@"LastOpen"];
}

- (id)initWithCoder:(NSCoder *)decoder {


    if ((self = [super init])) // Superclass init
    {
        _guid = [decoder decodeObjectForKey:@"FileGUID"];

        _fileName = [decoder decodeObjectForKey:@"FileName"];

        _fileDate = [decoder decodeObjectForKey:@"FileDate"];

        _pageCount = [decoder decodeObjectForKey:@"PageCount"];

        _currentPage = [decoder decodeObjectForKey:@"PageNumber"];

        _bookmarks = [[decoder decodeObjectForKey:@"Bookmarks"] mutableCopy];

        _fileSize = [decoder decodeObjectForKey:@"FileSize"];

        _lastOpen = [decoder decodeObjectForKey:@"LastOpen"];

        if (_bookmarks == nil) _bookmarks = [NSMutableIndexSet new];

        if (_guid == nil) _guid = [RoboDocument GUID];
    }

    return self;
}

@end
