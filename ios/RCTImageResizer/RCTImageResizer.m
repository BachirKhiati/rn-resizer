//
//  ImageResize.m
//  ChoozItApp
//
//  Created by Florian Rival on 19/11/15.
//

#include "RCTImageResizer.h"
#import "RNAlbumOptions.h"
#include "ImageHelpers.h"
#import <Photos/Photos.h>

#import <React/RCTImageLoader.h>


static NSString *albumNameFromType(PHAssetCollectionSubtype type);
static BOOL isAlbumTypeSupported(PHAssetCollectionSubtype type);

@implementation ImageResizer

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

bool saveImage(NSString * fullPath, UIImage * image, NSString * format, float quality)
{
    NSData* data = nil;
    if ([format isEqualToString:@"JPEG"]) {
        data = UIImageJPEGRepresentation(image, quality / 100.0);
    } else if ([format isEqualToString:@"PNG"]) {
        data = UIImagePNGRepresentation(image);
    }
    
    if (data == nil) {
        return NO;
    }
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager createFileAtPath:fullPath contents:data attributes:nil];
}

NSString * generateFilePathThumbnailImage(NSString * ext, NSString * outputPath)
{
    NSString* directory;
    directory = [outputPath stringByDeletingLastPathComponent];
    NSString* name = [outputPath lastPathComponent];
    NSString* fullName = [NSString stringWithFormat:@"%@.%@", name, ext];
    NSString* fullPath = [directory stringByAppendingPathComponent:fullName];
    
    
    return fullPath;
}

NSString * generateFilePath(NSString * ext, NSString * outputPath)
{
    NSString* directory;

    if ([outputPath length] == 0) {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        directory = [paths firstObject];
    } else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        if ([outputPath hasPrefix:documentsDirectory]) {
            directory = outputPath;
        } else {
            directory = [documentsDirectory stringByAppendingPathComponent:outputPath];
        }
        
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating documents subdirectory: %@", error);
            @throw [NSException exceptionWithName:@"InvalidPathException" reason:[NSString stringWithFormat:@"Error creating documents subdirectory: %@", error] userInfo:nil];
        }
    }

    NSString* name = [[NSUUID UUID] UUIDString];
    NSString* fullName = [NSString stringWithFormat:@"%@.%@", name, ext];
    NSString* fullPath = [directory stringByAppendingPathComponent:fullName];

    return fullPath;
}

NSString * generateDirectoryPath()
{
    NSString* directory;


        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        directory = [paths firstObject];
   return directory;
  
    }
    

    


UIImage * rotateImage(UIImage *inputImage, float rotationDegrees)
{

    // We want only fixed 0, 90, 180, 270 degree rotations.
    const int rotDiv90 = (int)round(rotationDegrees / 90);
    const int rotQuadrant = rotDiv90 % 4;
    const int rotQuadrantAbs = (rotQuadrant < 0) ? rotQuadrant + 4 : rotQuadrant;
    
    // Return the input image if no rotation specified.
    if (0 == rotQuadrantAbs) {
        return inputImage;
    } else {
        // Rotate the image by 80, 180, 270.
        UIImageOrientation orientation = UIImageOrientationUp;
        
        switch(rotQuadrantAbs) {
            case 1:
                orientation = UIImageOrientationRight; // 90 deg CW
                break;
            case 2:
                orientation = UIImageOrientationDown; // 180 deg rotation
                break;
            default:
                orientation = UIImageOrientationLeft; // 90 deg CCW
                break;
        }
        
        return [[UIImage alloc] initWithCGImage: inputImage.CGImage
                                                  scale: 1.0
                                                  orientation: orientation];
    }
}



RCT_EXPORT_METHOD(createResizedImage:(NSString *)path
                  width:(float)width
                  height:(float)height
                  format:(NSString *)format
                  quality:(float)quality
                  rotation:(float)rotation
                  outputPath:(NSString *)outputPath
                  callback:(RCTResponseSenderBlock)callback)
{
    CGSize newSize = CGSizeMake(width, height);
    
    //Set image extension
    NSString *extension = @"jpg";
    if ([format isEqualToString:@"PNG"]) {
        extension = @"png";
    }

    
    NSString* fullPath;
    @try {
        fullPath = generateFilePath(extension, outputPath);
    } @catch (NSException *exception) {
        callback(@[@"Invalid output path.", @""]);
        return;
    }

    [_bridge.imageLoader loadImageWithURLRequest:[RCTConvert NSURLRequest:path] callback:^(NSError *error, UIImage *image) {
        if (error || image == nil) {
            if ([path hasPrefix:@"data:"] || [path hasPrefix:@"file:"]) {
                NSURL *imageUrl = [[NSURL alloc] initWithString:path];
                image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
            } else {
                image = [[UIImage alloc] initWithContentsOfFile:path];
            }
            if (image == nil) {
                callback(@[@"Can't retrieve the file from the path.", @""]);
                return;
            }
        }

        // Rotate image if rotation is specified.
        if (0 != (int)rotation) {
            image = rotateImage(image, rotation);
            if (image == nil) {
                callback(@[@"Can't rotate the image.", @""]);
                return;
            }
        }

        // Do the resizing
        UIImage * scaledImage = [image scaleToSize:newSize];
        if (scaledImage == nil) {
            callback(@[@"Can't resize the image.", @""]);
            return;
        }

        // Compress and save the image
        if (!saveImage(fullPath, scaledImage, format, quality)) {
            callback(@[@"Can't save the image. Check your compression format and your output path", @""]);
            return;
        }
        NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fullPath];
        NSString *fileName = fileUrl.lastPathComponent;
        NSError *attributesError = nil;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&attributesError];
        NSNumber *fileSize = fileAttributes == nil ? 0 : [fileAttributes objectForKey:NSFileSize];
        NSDictionary *response = @{@"path": fullPath,
                                   @"uri": fileUrl.absoluteString,
                                   @"name": fileName,
                                   @"size": fileSize == nil ? @(0) : fileSize
                                   };
        
        callback(@[[NSNull null], response]);
    }];
}

RCT_EXPORT_METHOD(createThumbnailImage:(NSString *)path
                  width:(float)width
                  height:(float)height
                  format:(NSString *)format
                  quality:(float)quality
                  rotation:(float)rotation
                  outputPath:(NSString *)outputPath
                  callback:(RCTResponseSenderBlock)callback)
{
    CGSize newSize = CGSizeMake(width, height);
    
    //Set image extension
    NSString *extension = @"jpg";
    if ([format isEqualToString:@"PNG"]) {
        extension = @"jpg";
    }

    
    NSString* fullPath;
    @try {
        fullPath = generateFilePathThumbnailImage(extension, outputPath);
    } @catch (NSException *exception) {
        callback(@[@"Invalid output path.", @""]);
        return;
    }

    [_bridge.imageLoader loadImageWithURLRequest:[RCTConvert NSURLRequest:path] callback:^(NSError *error, UIImage *image) {
        if (error || image == nil) {
            if ([path hasPrefix:@"data:"] || [path hasPrefix:@"file:"]) {
                NSURL *imageUrl = [[NSURL alloc] initWithString:path];
                image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
            } else {
                image = [[UIImage alloc] initWithContentsOfFile:path];
            }
            if (image == nil) {
                callback(@[@"Can't retrieve the file from the path.", @""]);
                return;
            }
        }

        // Rotate image if rotation is specified.
        if (0 != (int)rotation) {
            image = rotateImage(image, rotation);
            if (image == nil) {
                callback(@[@"Can't rotate the image.", @""]);
                return;
            }
        }

        // Do the resizing
        UIImage * scaledImage = [image scaleToSize:newSize];
        if (scaledImage == nil) {
            callback(@[@"Can't resize the image.", @""]);
            return;
        }

        // Compress and save the image
        if (!saveImage(fullPath, scaledImage, format, quality)) {
            callback(@[@"Can't save the image. Check your compression format and your output path", @""]);
            return;
        }
        NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fullPath];
        NSString *fileName = fileUrl.lastPathComponent;
        NSError *attributesError = nil;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&attributesError];
        NSNumber *fileSize = fileAttributes == nil ? 0 : [fileAttributes objectForKey:NSFileSize];
        NSDictionary *response = @{@"path": fullPath,
                                   @"uri": fileUrl.absoluteString,
                                   @"name": fileName,
                                   @"size": fileSize == nil ? @(0) : fileSize
                                   };
        
        callback(@[[NSNull null], response]);
    }];
}



RCT_EXPORT_METHOD(exists:(NSString *)imagePath
                  callback:(RCTResponseSenderBlock)callback)
{
NSString *path = [imagePath stringByAppendingString:@".jpg"];
 BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
   NSDictionary *response = @{@"status": [NSNumber numberWithBool:fileExists]
                                  
                                   };
        callback(@[[NSNull null],response]);
}



RCT_EXPORT_METHOD(tempPath:
                  callback:(RCTResponseSenderBlock)callback)
{
    
    NSString* fullPath;
    @try {
        fullPath = generateDirectoryPath();
    } @catch (NSException *exception) {
        callback(@[@"Invalid output path.", @""]);
        return;
    }



         NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fullPath];

        NSDictionary *response = @{@"path": fullPath,
                                   @"uri": fileUrl.absoluteString,

                                   };
        
        callback(@[[NSNull null], response]);
  
}

RCT_EXPORT_METHOD(getAlbumList:
                    callback:(RCTResponseSenderBlock)callback)
{
//      PHFetchResult<PHAssetCollection *> *collections =
//      [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
//                                               subtype:PHAssetCollectionSubtypeAny
//                                               options:nil];
//
//      [collections enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        PHAssetCollectionSubtype type = [obj assetCollectionSubtype];
//        if (!isAlbumTypeSupported(type)) {
//          return;
//        }
//
//        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
//        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
//        fetchOptions.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ];
//        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options: fetchOptions];
//        PHAsset *coverAsset = fetchResult.lastObject;
//
//        if (coverAsset) {
//            NSDictionary *album = @{@"count": @(fetchResult.count),
//                                    @"name": albumNameFromType(type),
//                                    // Photos Framework asset scheme ph://
//                                    @"cover": [NSString stringWithFormat:@"ph://%@", coverAsset.localIdentifier] };
//            [result addObject:album];
//        }
//      }];
     // resolve(result);
    
    PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
      NSMutableArray *result = [[NSMutableArray alloc] init];
    userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    [result addObject:@"Library"];
    
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        [result addObject:collection.localizedTitle];
    }];
    NSDictionary *response = @{@"albums": result};
        callback(@[[NSNull null], response]);
}




@end


