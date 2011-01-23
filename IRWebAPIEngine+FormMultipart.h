//
//  IRWebAPIEngine+FormMultipart.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine.h"


extern NSString * const kIRWebAPIEngineRequestContextFormMultipartFieldsKey;

@interface IRWebAPIEngine (FormMultipart)

+ (IRWebAPIRequestContextTransformer) defaultFormMultipartTransformer;

@end





/*

	+defaultFormMultipartTransformer emits a block that expects :
	
	{
	
		kIRWebAPIEngineRequestContextFormMultipartFieldsKey = {
		
			aFormName = "aStringValue",
			
			anotherFormName = file://myFile.txt ,
			
			anotherThing = <00325296>
		
		}
	
	}
	
	Where a string value gets sent, a URL gets mapped and dumped, its UTI guessed, and a NSData simply copied.
	
	The HTTP method is changed to POST and there must be nothing in the old HTTP body.
	
	
	Since transforming could be expensive you explicitly hook the transformer up.
	This category works with the +defaultCleanUpTemporaryFilesResponseTransformer so as to keep things neat.
	
	Here’s a use case:
	
	- (void) testMultipart {
		
		NSString *path = [[IRWebAPIEngine newTemporaryFileURL] path];
		
		[[NSData dataWithData:UIImagePNGRepresentation(( ^ {
		
			UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);
			CGContextRef context = UIGraphicsGetCurrentContext();
			
			CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
			CGContextFillRect(context, [UIScreen mainScreen].bounds);
				
			[self.window.layer renderInContext:ctx];
				
			UIImage *returnedImage = UIGraphicsGetImageFromCurrentImageContext();
			
			UIGraphicsEndImageContext();
			
			
			return returnedImage;
		
		})())] writeToFile:path atomically:YES];
		
		
		IRWebAPIEngine *testEngine = [[[IRWebAPIEngine alloc] initWithContext:(( ^ {
		
			IRWebAPIContext *returnedContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"http://Museo.local/~evadne/postTest/"]] autorelease];
			
			return returnedContext;
		
		})())] autorelease];
		
		[testEngine.globalRequestPreTransformers addObject:[[testEngine class] defaultFormMultipartTransformer]];
		[testEngine.globalResponsePostTransformers addObject:[[testEngine class] defaultCleanUpTemporaryFilesResponseTransformer]];
		
		[testEngine fireAPIRequestNamed:@"test.php" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
		
			[NSDictionary dictionaryWithObjectsAndKeys:
			
				[NSURL fileURLWithPath:path], @"image",
			
			nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		
		nil] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
			NSLog(@"Success: %@", inResponseOrNil);
		
		} failureHandler:nil];

	}
	
	
	This PHP snippet works with OS X 10.6’s bundled Apache:
	
	<?php

		foreach ($_FILES as $file)
		if ($file['error'] == UPLOAD_ERR_OK)
		move_uploaded_file($file["tmp_name"], $_SERVER['SCRIPT_FILENAME'] . ("." . time() . ""));

	?>

*/




