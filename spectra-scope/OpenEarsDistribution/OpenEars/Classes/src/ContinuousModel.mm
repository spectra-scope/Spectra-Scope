//  OpenEars 
//  http://www.politepix.com/openears
//
//  ContinuousModel.mm
//  OpenEars
//
//  ContinuousModel is a class which consists of the continuous listening loop used by Pocketsphinx.
//
//  This is a Pocketsphinx continuous listening loop based on modifications to the Pocketsphinx file continuous.c.
//
//  Copyright Politepix UG (hatfungsbeschränkt) 2012 excepting that which falls under the copyright of Carnegie Mellon University as part
//  of their file continuous.c.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  Excepting that which falls under the license of Carnegie Mellon University as part of their file continuous.c, 
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.

//
//  Header for original source file continuous.c which I learned from to create this file is as follows:
//
/* -*- c-basic-offset: 4; indent-tabs-mode: nil -*- */
/* ====================================================================
 * Copyright (c) 1999-2001 Carnegie Mellon University.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * This work was supported in part by funding from the Defense Advanced 
 * Research Projects Agency and the National Science Foundation of the 
 * United States of America, and the CMU Sphinx Speech Consortium.
 *
 * THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY ``AS IS'' AND 
 * ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
 * NOR ITS EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ====================================================================
 *
 */
/*
 * demo.c -- An example SphinxII program using continuous listening/silence filtering
 * 		to segment speech into utterances that are then decoded.
 * 
 * HISTORY
 *
 * 15-Jun-99    Kevin A. Lenzo (lenzo@cs.cmu.edu) at Carnegie Mellon University
 *              Added i386_linux and used ad_open_sps instead of ad_open
 * 
 * 14-Jun-96	M K Ravishankar (rkm@cs.cmu.edu) at Carnegie Mellon University.
 * 		Created.
 */

#import "ContinuousModel.h"
#import "pocketsphinx.h"
#import "ContinuousADModule.h"
#import "unistd.h"
#import "PocketsphinxRunConfig.h"
#import "fsg_search_internal.h"
#import "RuntimeVerbosity.h"
#import "AudioConstants.h"
#import "CommandArray.h"


@implementation ContinuousModel

@synthesize inMainRecognitionLoop; // Have we entered the main part of the loop yet?
@synthesize exitListeningLoop; // Should we be breaking out of the loop at the nearest opportunity?
@synthesize thereIsALanguageModelChangeRequest;
@synthesize languageModelFileToChangeTo;
@synthesize dictionaryFileToChangeTo;
@synthesize secondsOfSilenceToDetect;
@synthesize returnNbest;
@synthesize nBestNumber;
@synthesize calibrationTime;
@synthesize outputAudio;
@synthesize processSpeechLocally;
@synthesize returnNullHypotheses;
@synthesize delegate;
@synthesize pathToTestFile;
@synthesize modelName;

extern int openears_logging;
extern int verbose_pocketsphinx;
extern int returner;

#if TARGET_IPHONE_SIMULATOR
NSString * const DeviceOrSimulator = @"Simulator";
#else
NSString * const DeviceOrSimulator = @"Device";
#endif

- (id) init {
    if (self = [super init]) {
        outputAudio = FALSE;
        exitListeningLoop = 0;
        thereIsALanguageModelChangeRequest = FALSE;
        returnNullHypotheses = FALSE;
    }
    return self;
}

- (void)dealloc {
	[languageModelFileToChangeTo release];
	[dictionaryFileToChangeTo release];
    [pathToTestFile release];
    [modelName release];
    [super dealloc];
}

- (void) performOpenEarsNotificationOnMainThread:(NSString *)notificationNameAsString withOptionalObjects:(NSArray *)objects andKeys:(NSArray *)keys {
        
    NSMutableArray *objectsArray = [[NSMutableArray alloc] init];
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    if(objects || keys) {
        if ([objects count] != [keys count]) {
        NSLog(@"Error in performOpenEarsNotificationOnMainThread: there are optional objects and keys but not the same amount of both, so there will probably be a crash now.");
        }
         
        [objectsArray addObjectsFromArray:objects];
        [keysArray addObjectsFromArray:keys];

    }
        
    [objectsArray insertObject:notificationNameAsString atIndex:0];
    [keysArray insertObject:@"OpenEarsNotificationType" atIndex:0];

    NSDictionary *userInfoDictionary = [[NSDictionary alloc] initWithObjects:objectsArray forKeys:keysArray];
    NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
       
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
    
    [userInfoDictionary release];
    
    [objectsArray release];
    
    [keysArray release];
    
}

- (NSString *)languageModelFileToChangeTo {
	if (languageModelFileToChangeTo == nil) {
		languageModelFileToChangeTo = [[NSString alloc] init];
	}
	return languageModelFileToChangeTo;
}

- (NSString *) compileKnownWordsFromFileAtPath:(NSString *)filePath {
	NSArray *dictionaryArray = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSMutableString *allWords = [[[NSMutableString alloc] init]autorelease];
	for(NSString *string in dictionaryArray) {
		NSArray *lineArray = [string componentsSeparatedByString:@"\t"];
		[allWords appendString:[NSString stringWithFormat:@"%@\n",[lineArray objectAtIndex:0]]];
	}
	return allWords;
}

- (void) clearBuffers {
    clear_buffers();    
}

- (void) changeLanguageModelForDecoder:(ps_decoder_t *)pocketsphinxDecoder languageModelIsJSGF:(BOOL)languageModelIsJSGF {

    int fatalErrors = 0;
    
    if(languageModelIsJSGF == TRUE) {
        
		NSArray *dictionaryArray = [[NSString stringWithContentsOfFile:self.dictionaryFileToChangeTo encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
		int updateValue = 0;
		int count = 1;
		int add_word_result = 0;
        
        NSCharacterSet *nonWhitespaceCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
        
        NSMutableArray *mutableCleaningArray = [[NSMutableArray alloc] init];

        for(NSString *string in dictionaryArray) {
            
            if(([string length] > 0) && [string rangeOfCharacterFromSet:nonWhitespaceCharacterSet].location != NSNotFound) { // This string has a length of at least one and it doesn't exclusively consist of whitespace or newlines, so it can be parsed by what follows.
                [mutableCleaningArray addObject:string];
            }
            
        }
        
        NSArray *dictionaryProcessingArray = [[NSArray alloc] initWithArray:(NSArray *)mutableCleaningArray];
        [mutableCleaningArray release];
        
		for(NSString *string in dictionaryProcessingArray) {
           
            NSArray *lineArray = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSMutableString *mutablePhonesString = [[NSMutableString alloc] init];
            int i;
            for ( i = 0; i < [lineArray count]; i++ ) {
                if(i > 0) [mutablePhonesString appendString:[NSString stringWithFormat:@"%@ ",[lineArray objectAtIndex:i]]];
            }
            
            NSRange deletionRange = {[mutablePhonesString length]-1,1};
            [mutablePhonesString deleteCharactersInRange:deletionRange];
            
            if(count < [dictionaryProcessingArray count]) {
                updateValue = 0;
            } else {
                updateValue = 1;
            }
 
            add_word_result = ps_add_word(pocketsphinxDecoder,(char *)[[lineArray objectAtIndex:0] UTF8String], (char *)[[lineArray objectAtIndex:1] UTF8String],updateValue);
            [mutablePhonesString release];
            
            if(add_word_result > -1) {
                if(openears_logging == 1) NSLog(@"%@ was added to dictionary",[lineArray objectAtIndex:0]);
            } else {
                if(openears_logging == 1) NSLog(@"%@ was not added to dictionary, perhaps because it is already in the dictionary",[lineArray objectAtIndex:0]);
            }
            
            count++;
            
		}
        
        [dictionaryProcessingArray release];
        
        
		if(openears_logging == 1) NSLog(@"A request has been made to change a JSGF grammar on the fly.");
		fsg_set_t *fsgs = ps_get_fsgset(pocketsphinxDecoder);
        
         fsg_set_remove_byname(fsgs, fsg_model_name(fsgs->fsg));
        
		jsgf_t *jsgf;
		fsg_model_t *fsg;
        jsgf_rule_t *rule;
		char const *path = (char *)[self.languageModelFileToChangeTo UTF8String];
        
        if ((jsgf = jsgf_parse_file(path, NULL)) == NULL) {
			if(openears_logging == 1) NSLog(@"Error: no JSGF file at path.");
            fatalErrors++;
		}
        rule = NULL;
        
		jsgf_rule_iter_t *itor;
        
		for (itor = jsgf_rule_iter(jsgf); itor;
			 itor = jsgf_rule_iter_next(itor)) {
			rule = jsgf_rule_iter_rule(itor);
			if (jsgf_rule_public(rule))
				break;
            
            if (rule == NULL) {
                if(openears_logging == 1) NSLog(@"Error: No public rules found in %s", path);
                fatalErrors++;
            }
        }
        
        if(openears_logging == 1)NSLog(@"current language weight is %d",fsgs->lw);
        
        int languageWeight = kJSGFLanguageWeight; // For some reason this value is a) lost and b) now an int instead of a float. Resetting it manually at this time helps a lot with recognition quality.
        
		fsg = jsgf_build_fsg(jsgf, rule, pocketsphinxDecoder->lmath, languageWeight);
      
        if (fsg_set_add(fsgs, fsg_model_name(fsg), fsg) != fsg) {
			if(openears_logging == 1) NSLog(@"Error: could not add finite state grammar to set.");
            fatalErrors++;
        } else {
            
		}
        
        if (fsg_set_select(fsgs, fsg_model_name(fsg)) == NULL) {
			if(openears_logging == 1) NSLog(@"Error: could not select new grammar.");
            fatalErrors++;
		}
        
		ps_update_fsgset(pocketsphinxDecoder);
        
	} else {
        
		if(openears_logging == 1) NSLog(@"A request has been made to change an ARPA grammar on the fly. The language model to change to is %@", self.languageModelFileToChangeTo);
		NSNumber *languageModelID = [NSNumber numberWithInt:999];
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSError *error = nil;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:self.languageModelFileToChangeTo error:&error];
		if(error) {
			if(openears_logging == 1) NSLog(@"Error: couldn't get attributes of language model file.");
            fatalErrors++;
		} else {
			if(openears_logging == 1) NSLog(@"In this session, the requested language model will be known to Pocketsphinx as id %@.",[fileAttributes valueForKey:NSFileSystemFileNumber]);
			languageModelID = [fileAttributes valueForKey:NSFileSystemFileNumber];
		}
        
		[fileManager release];
        
		ngram_model_t *baseLanguageModel, *newLanguageModelToAdd;
        
		newLanguageModelToAdd = ngram_model_read(pocketsphinxDecoder->config, (char *)[self.languageModelFileToChangeTo UTF8String], NGRAM_AUTO, pocketsphinxDecoder->lmath);
        
		baseLanguageModel = ps_get_lmset(pocketsphinxDecoder);
        
		if(openears_logging == 1) NSLog(@"languageModelID is %s",(char *)[[languageModelID stringValue] UTF8String]);
		ngram_model_set_add(baseLanguageModel, newLanguageModelToAdd, (char *)[[languageModelID stringValue] UTF8String], 1.0, TRUE);
		ngram_model_set_select(baseLanguageModel, (char *)[[languageModelID stringValue] UTF8String]);
        
		ps_update_lmset(pocketsphinxDecoder, baseLanguageModel);
        
		int loadingDictionaryResult = ps_load_dict(pocketsphinxDecoder, (char *)[self.dictionaryFileToChangeTo UTF8String],NULL, NULL);
        
		if(loadingDictionaryResult > -1) {
			if(openears_logging == 1) NSLog(@"Success loading the dictionary file %@.",self.dictionaryFileToChangeTo);
		} else {
			if(openears_logging == 1) NSLog(@"Error: could not load the specified dictionary file.");
            fatalErrors++;
		}
        
	}
    
    if(fatalErrors > 0) { // Language model or grammar switch wasn't successful, report the failure and reset the variables.

        if(openears_logging == 1) NSLog(@"There were too many errors to switch the language model or grammar, please search the console for the word 'error' to investigate the issues.");
        
        self.languageModelFileToChangeTo = nil;
		self.thereIsALanguageModelChangeRequest = FALSE;
        
    } else { // Language model or grammar switch appears to have been successful.

        [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidChangeLanguageModel" withOptionalObjects:[NSArray arrayWithObjects:self.languageModelFileToChangeTo, self.dictionaryFileToChangeTo,nil] andKeys:[NSArray arrayWithObjects:@"LanguageModelFilePath",@"DictionaryFilePath",nil]];

		self.languageModelFileToChangeTo = nil;
		self.thereIsALanguageModelChangeRequest = FALSE;
        
		if(openears_logging == 1) NSLog(@"Changed language model. Project has these words in its dictionary:\n%@", [self compileKnownWordsFromFileAtPath:self.dictionaryFileToChangeTo]);
    }
}

- (PocketsphinxAudioDevice *) continuousAudioDevice { // Return the device to an Objective-C class.
	return audioDevice;	
}

- (CFStringRef) getCurrentRoute {
	if(audioDevice != NULL) {
        if(audioDevice->currentRoute != NULL) {
            return audioDevice->currentRoute;
        } else {
            return (CFStringRef)@"NoAudioDeviceRoute";        
        }
    }   
	return (CFStringRef)@"NoAudioDeviceRoute";
}


- (void) setCurrentRouteTo:(NSString *)newRoute {
	if(audioDevice != NULL && audioDevice->currentRoute != NULL) {
		audioDevice->currentRoute = (CFStringRef)newRoute;
	}
}

- (int) getRecognitionIsInProgress {
	if(audioDevice != NULL) {
		return audioDevice->recognitionIsInProgress;
	}
	return 0;
}

- (void) setRecognitionIsInProgressTo:(int)recognitionIsInProgress {
	if(audioDevice != NULL) {
		audioDevice->recognitionIsInProgress = recognitionIsInProgress;
	}
}


- (int) getRecordData {
	if(audioDevice != NULL) {
		return audioDevice->recordData;
	}
	return 0;
}

- (void) setRecordDataTo:(int)recordData {
	if(audioDevice != NULL) {
		audioDevice->recordData = recordData;
	}
}

- (Float32) getMeteringLevel {
	if(audioDevice != NULL) {	
		return pocketsphinxAudioDeviceMeteringLevel(audioDevice);
	}
	return 0.0;
}



#pragma mark -
#pragma mark Pocketsphinx Listening Loop


- (void) setupCalibrationBuffer {
	
	int numberOfRounds = 25; // This is the minimum number of rounds that appear to be required to be available under normal usage;
	int numberOfSamples = kPredictedSizeOfRenderFramesPerCallbackRound; // This is the current number of samples that is called in a single callback buffer round but this could change based on hardware, etc so keep an eye on it
	int safetyMultiplier = audioDevice->bps * 3; // this is the safety multiplier so that under normal usage we don't overrun this buffer, bps * 3 for device independence.

	if(audioDevice->calibrationBuffer == NULL) {
		audioDevice->calibrationBuffer = (SInt16*) malloc(audioDevice->bps * numberOfSamples * numberOfRounds * safetyMultiplier); // this only needs to be the size of the amount of data used to calibrate, and then some		
	} else {
		audioDevice->calibrationBuffer = (SInt16*) realloc(audioDevice->calibrationBuffer, audioDevice->bps * numberOfSamples * numberOfRounds * safetyMultiplier); // this only needs to be the size of the amount of data used to calibrate, and then some				
	}
	
	audioDevice->availableSamplesDuringCalibration = 0;
	audioDevice->samplesReadDuringCalibration = 0;
}


- (void) putAwayCalibrationBuffer {
	if(audioDevice->calibrationBuffer != NULL) {
		free(audioDevice->calibrationBuffer);
		audioDevice->calibrationBuffer = NULL;
	}
	audioDevice->availableSamplesDuringCalibration = 0;
	audioDevice->samplesReadDuringCalibration = 0;
}

- (void) changeLanguageModelToFile:(NSString *)languageModelPathAsString withDictionary:(NSString *)dictionaryPathAsString {
	self.thereIsALanguageModelChangeRequest = TRUE;
	self.languageModelFileToChangeTo = languageModelPathAsString;
	self.dictionaryFileToChangeTo = dictionaryPathAsString;
}

- (void) checkWhetherJSGFSettingOf:(BOOL)languageModelIsJSGF LooksCorrectForThisFilename:(NSString *)languageModelPath {
    
    if([languageModelPath hasSuffix:@".gram"] || [languageModelPath hasSuffix:@".GRAM"] || [languageModelPath hasSuffix:@".grammar"] || [languageModelPath hasSuffix:@".GRAMMAR"] || [languageModelPath hasSuffix:@".jsgf"] || [languageModelPath hasSuffix:@".JSGF"]) {
        
        // This is probably a JSGF file. Let's see if the languageModelIsJSGF seems correct for that case.
        if(!languageModelIsJSGF) { // Probable JSGF file with the ARPA bit set
            if(openears_logging == 1) NSLog(@"The file you've sent to the decoder appears to be a JSGF grammar based on its naming, but you have not set languageModelIsJSGF: to TRUE. If you are experiencing recognition issues, there is a good chance that this is the reason for it.");
        }
        
    } else if([languageModelPath hasSuffix:@".lm"] || [languageModelPath hasSuffix:@".LM"] || [languageModelPath hasSuffix:@".languagemodel"] || [languageModelPath hasSuffix:@".LANGUAGEMODEL"] || [languageModelPath hasSuffix:@".arpa"] || [languageModelPath hasSuffix:@".ARPA"] || [languageModelPath hasSuffix:@".dmp"] || [languageModelPath hasSuffix:@".DMP"]) {
        
        // This is probably an ARPA file. Let's see if the languageModelIsJSGF seems correct for that case.        
        if(languageModelIsJSGF) { // Probable ARPA file with the JSGF bit set
            if(openears_logging == 1) NSLog(@"The file you've sent to the decoder appears to be an ARPA-style language model based on its naming, but you have set languageModelIsJSGF: to TRUE. If you are experiencing recognition issues, there is a good chance that this is the reason for it.");
        }
        
    } else { // It isn't clear from the suffix what kind of file this is, which could easily be a bad sign so let's mention it.
        if(openears_logging == 1) NSLog(@"The LanguageModelAtPath filename that was submitted to listeningLoopWithLanguageModelAtPath: doesn't have a suffix that is usually seen on an ARPA model or a JSGF model, which are the only two kinds of models that OpenEars supports. If you are having difficulty with your project, you should probably take a look at the language model or grammar file you are trying to submit to the decoder and/or its naming.");
    }
}

- (void) availableBuffer:(SInt16 *)buffer withLength:(int)length {
    NSData *data =[[NSData alloc] initWithBytes:buffer length:length];
    NSArray *objectsArray = [[NSArray alloc] initWithObjects:data,nil];
    NSArray *keysArray = [[NSArray alloc] initWithObjects:@"Buffer", nil];
    [self performOpenEarsNotificationOnMainThread:@"AvailableBuffer" withOptionalObjects:objectsArray andKeys:keysArray];
    [objectsArray release];
    [keysArray release];
    [data release];
}

- (NSString *) pathToCmnPlistAsString {
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"cmnvalues.plist"];
}

- (void) removeCmnPlist {

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *fileRemovalError = nil;
    BOOL removalSuccess = [fileManager removeItemAtPath:[self pathToCmnPlistAsString] error:&fileRemovalError];
    if (removalSuccess == FALSE) {
        if(openears_logging==1) {
            NSLog(@"Error while removing cmn plist: %@", [fileRemovalError description]);    
        }
    }
}

- (BOOL) cmnInitPlistFileExists {
    if ( [[NSFileManager defaultManager] fileExistsAtPath:[self pathToCmnPlistAsString]] ) {
        return TRUE;
    } else {
        return FALSE;
    }
}

- (NSMutableDictionary *) loadCmnPlistIntoDictionary {
 
    return [NSMutableDictionary dictionaryWithContentsOfFile:[self pathToCmnPlistAsString]];
}

- (BOOL) writeOutCmnPlistFromDictionary:(NSMutableDictionary *)mutableDictionary {
    return [mutableDictionary writeToFile:[self pathToCmnPlistAsString] atomically:YES];
}

- (BOOL) valuesLookReasonableforCmn:(float)cmn andRoute:(CFStringRef)route {
 
    if(cmn != cmn || route == NULL) { // If there are no values here, stop before trying to read them at all.
        return FALSE;
    }
    
    if((cmn > 3 && cmn < 120) && (([(NSString *)route length] > 2) && ([(NSString *)route length] < 100))) {
        return TRUE;
    } else {
        return FALSE;
    }
}

- (void) finalizeCmn:(float)cmnFloat atRoute:(CFStringRef)routeString forAcousticModelAtPath:(NSString *)acousticModelPath {

    NSMutableDictionary *mutableCmnPlistDictionary = nil;

    if([self valuesLookReasonableforCmn:cmnFloat andRoute:routeString] == TRUE) {
        
        NSNumber *cmnNumber = [NSNumber numberWithFloat:cmnFloat];
        
        NSString *addressToValue = [self addressToCMNValueForAcousticModelAtPath:acousticModelPath atRoute:routeString];

        if([self cmnInitPlistFileExists] == TRUE) {
            mutableCmnPlistDictionary = [self loadCmnPlistIntoDictionary]; 
            [mutableCmnPlistDictionary setObject:cmnNumber forKey:addressToValue];   
        } else {
            mutableCmnPlistDictionary = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:cmnNumber,nil] forKeys:[NSArray arrayWithObjects:addressToValue,nil]];
        }
    }

    BOOL writeOutSuccess = [self writeOutCmnPlistFromDictionary:mutableCmnPlistDictionary];

    if(writeOutSuccess == FALSE) {
        NSLog(@"Writing out cmn plist was not successful");
    }
}

- (void) setDecoder:(ps_decoder_t *)pocketSphinxDecoder toCmnInit:(float)previouscmn {
    if (pocketSphinxDecoder->acmod->fcb->cmn_struct) {
        
        NSString *previousCmnAsString = [[NSNumber numberWithFloat:previouscmn]stringValue];
        const char *floatAsChar = [previousCmnAsString UTF8String];
        char *c, *cc, *vallist;
        int32 nvals;
        
        vallist = ckd_salloc(floatAsChar);
        c = vallist;
        nvals = 0;
        while (nvals < pocketSphinxDecoder->acmod->fcb->cmn_struct->veclen
               && (cc = strchr(c, ',')) != NULL) {
            *cc = '\0';
            pocketSphinxDecoder->acmod->fcb->cmn_struct->cmn_mean[nvals] = FLOAT2MFCC(atof(c));
            c = cc + 1;
            ++nvals;
        }
        if (nvals < pocketSphinxDecoder->acmod->fcb->cmn_struct->veclen && *c != '\0') {
            pocketSphinxDecoder->acmod->fcb->cmn_struct->cmn_mean[nvals] = FLOAT2MFCC(atof(c));
        }
        ckd_free(vallist);
    }
}

- (void) setUpPreviousCmnValuesForRoute:(CFStringRef)routeString acousticModelAtPath:(NSString *)acousticModelPath withDecoder:(ps_decoder_t *)pocketSphinxDecoder {
    
    // if there is a plist and
    // if the plist has an entry for this route and acoustic model and device
    // set the cmninit value to that entry.
    if([self cmnInitPlistFileExists]) {
        NSDictionary *cmnPlistDictionary = (NSDictionary *)[self loadCmnPlistIntoDictionary];
        
        NSString *addressToValue = [self addressToCMNValueForAcousticModelAtPath:acousticModelPath atRoute:routeString];
        
        if([cmnPlistDictionary objectForKey:addressToValue]) {
            float previouscmn = [[cmnPlistDictionary objectForKey:addressToValue]floatValue];
            if((previouscmn == previouscmn) && (previouscmn > 3) && (previouscmn < 100)) { // I fink you not freeky and I like you a lot.
                [self setDecoder:pocketSphinxDecoder toCmnInit:previouscmn];
            }
        }
    }
}

- (NSString *) addressToCMNValueForAcousticModelAtPath:(NSString *)acousticModelPath atRoute:(CFStringRef)routeString {

    return [NSString stringWithFormat:@"%@.%@.%@.%@",self.modelName,DeviceOrSimulator,[acousticModelPath lastPathComponent],(NSString *)routeString];
}

- (void) listeningLoopWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF { // The big recognition loop.
    
    self.modelName = NSStringFromClass([self class]);
    
    if(self.processSpeechLocally) [self checkWhetherJSGFSettingOf:languageModelIsJSGF LooksCorrectForThisFilename:languageModelPath];
    
    static ps_decoder_t *pocketSphinxDecoder; // The Pocketsphinx decoder which will perform the actual speech recognition on recorded speech.
    FILE *err_set_logfp(FILE *logfp); // This function will allow us to make Pocketsphinx run quietly.
    
    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxRecognitionLoopDidStart" withOptionalObjects:nil andKeys:nil];

	if(openears_logging == 1) NSLog(@"Recognition loop has started");
	
	UInt32 maximumAndBufferIndices = 32368;
	int16 audioDeviceBuffer[maximumAndBufferIndices]; // The following are all used by Pocketsphinx.
    int32 speechData;
	int32 timestamp;
	int32 remainingSpeechData = 0;
	int32 recognitionScore;
    char const *hypothesis;
    char const *utteranceID;
    cont_ad_t *continuousListener;
	    
    if(verbose_pocketsphinx == 0) {

        err_set_logfp(NULL); // If verbose_pocketsphinx isn't defined, this will quiet the output from Pocketsphinx.
    }
	
    if(self.processSpeechLocally) {
            
        CommandArray *commandArrayModel = [[CommandArray alloc] init];
        NSArray *commandArray = [commandArrayModel commandArrayForlanguageModel:languageModelPath dictionaryPath:dictionaryPath acousticModelPath:acousticModelPath isJSGF:languageModelIsJSGF];

        
        char* argv[[commandArray count]]; // We're simulating the command-line run arguments for Pocketsphinx.
        
        for (int i = 0; i < [commandArray count]; i++ ) { // Grab all the set arguments.

            char *argument = const_cast<char*> ([[commandArray objectAtIndex:i]UTF8String]);
            argv[i] = argument;
        }
        
        arg_t cont_args_def[] = { // Grab any extra arguments.
            POCKETSPHINX_OPTIONS,
            { "-argfile", ARG_STRING, NULL, "Argument file giving extra arguments." },
            CMDLN_EMPTY_OPTION
        };
        
        cmd_ln_t *configuration; // The Pocketsphinx run configuration.
        
        if ([commandArray count] < 3) { // Fail if there aren't enough arguments.
            if(openears_logging == 1) NSLog(@"Initial Pocketsphinx command failed because there aren't any arguments in the command");
            
            [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
            configuration = cmd_ln_parse_file_r(NULL, cont_args_def, argv[1], TRUE);
        }  else { // Set the Pocketsphinx run configuration to the selected arguments and values.
            configuration = cmd_ln_parse_r(NULL, cont_args_def, [commandArray count], argv, FALSE);
        }
        
        pocketSphinxDecoder = ps_init(configuration); // Initialize the decoder.

        [commandArrayModel release];
        
        cmd_ln_free_r(configuration);

    }


    
    BOOL runTest = FALSE;
    
    const char *localPathToTestFile = NULL;
    
    if(self.pathToTestFile && ([self.pathToTestFile length] > 10)) { // There is a test file request.
        
        runTest = TRUE;
        localPathToTestFile = [self.pathToTestFile UTF8String];        
    }

    if ((audioDevice = openAudioDevice("device",kSamplesPerSecond,runTest,localPathToTestFile)) == NULL) { // Open the audio device (actually the struct containing the Audio Unit).
		if(openears_logging == 1) NSLog(@"openAudioDevice failed");
        
        [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
	
	}
	if(!self.pathToTestFile || ([self.pathToTestFile length] < 10)) { // If we're testing we don't use SmartCMN
   

        [self setUpPreviousCmnValuesForRoute:audioDevice->currentRoute acousticModelAtPath:acousticModelPath withDecoder:pocketSphinxDecoder]; // If we have previous cmn init values for this app, device, route and acoustic model, let's use them since they generally have to be more accurate than a naive init value
    }    
    if ((continuousListener = cont_ad_init(audioDevice, readBufferContents)) == NULL) { // Initialize the continuous recognition module.
        if(openears_logging == 1) NSLog(@"cont_ad_init failed");
        [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
	}
	
	audioDevice->recordData = 1; // Set the device to record data rather than ignoring it (it will ignore data when PocketsphinxController receives the suspendRecognition method).
	audioDevice->recognitionIsInProgress = 1;
	
    if (startRecording(audioDevice) < 0) { // Start recording.
        if(openears_logging == 1) NSLog(@"startRecording failed");
        [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
	}
	
	[self setupCalibrationBuffer];
	audioDevice->roundsOfCalibration = 0;
	audioDevice->calibrating = TRUE;
	
    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidStartCalibration" withOptionalObjects:nil andKeys:nil];
    
	// Forward notification that calibration is starting to OpenEarsEventsObserver.
	if(openears_logging == 1) NSLog(@"Calibration has started");
	
    if(self.calibrationTime != 1 && self.calibrationTime != 2 && self.calibrationTime != 3) {
        self.calibrationTime = 1;
    }
    
	[NSThread sleepForTimeInterval:self.calibrationTime + 1.2]; // Getting some samples in the buffer is necessary before we start calibrating.
    
    continuousListener->calibration_time = self.calibrationTime;
    
    if (cont_ad_calib(continuousListener) < 0) { // Start calibration.
		if(openears_logging == 1) NSLog(@"cont_ad_calib failed");
        [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
	}
	
    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidCompleteCalibration" withOptionalObjects:nil andKeys:nil];

	// Forward notification that calibration finished to OpenEarsEventsObserver.
	if(openears_logging == 1) NSLog(@"Calibration has completed");
	
	audioDevice->calibrating = FALSE;
	audioDevice->roundsOfCalibration = 0;
	[self putAwayCalibrationBuffer];

	if(openears_logging == 1 && self.processSpeechLocally) NSLog(@"Project has these words in its dictionary:\n%@", [self compileKnownWordsFromFileAtPath:dictionaryPath]);
    
    for (;;) { // This is the main loop.

        if(audioDevice->takeBuffersFromTestFile == TRUE && (audioDevice->positionInTestFile == audioDevice->bytesInTestFile)) {
            audioDevice->takeBuffersFromTestFile = FALSE;
            [self performOpenEarsNotificationOnMainThread:@"TestRecognitionCompleted" withOptionalObjects:nil andKeys:nil];
            audioDevice->pathToTestFile = "";
            audioDevice->bytesInTestFile = 0;
            audioDevice->positionInTestFile = 0;
            free(audioDevice->testFileBuffer);
        }
        
		self.inMainRecognitionLoop = TRUE; // Note that we're in the main loop.
		
		if(exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
		
		// We're now listening for speech.
        
        if(audioDevice->recordData==1) { // We only do this notification if we didn't end up here due to a suspension.
            
            if(openears_logging == 1) NSLog(@"Listening.");
            
            [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidStartListening" withOptionalObjects:nil andKeys:nil];
            
            // Forward notification that we're now listening for speech to OpenEarsEventsObserver.
            
            // If there is a request to change the lm let's do it here:
            
            if(self.thereIsALanguageModelChangeRequest == TRUE && self.processSpeechLocally) {
                
                if(openears_logging == 1) NSLog(@"there is a request to change to the language model file %@", self.languageModelFileToChangeTo);
                
                [self changeLanguageModelForDecoder:pocketSphinxDecoder languageModelIsJSGF:languageModelIsJSGF];
                
            }
            
        }
        // Wait for speech and sleep when we don't have any yet.
        
        while ((speechData = cont_ad_read(continuousListener, audioDeviceBuffer, maximumAndBufferIndices)) == 0) {

            usleep(30000);
            
            if(self.exitListeningLoop == 1 || self.thereIsALanguageModelChangeRequest == TRUE) break; // Break if we're trying to exit the loop.

        }
        
        if(self.thereIsALanguageModelChangeRequest == TRUE) { // Loop around to deal with the language model change right now

            continue;
        }
        
        if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
        
        if (speechData < 0) { // This is an error.
			if(openears_logging == 1) NSLog(@"cont_ad_read failed");
             [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
		}

        BOOL no_search_false = FALSE; // The crashing bug from this in 0.6.1 appears to be fixed now.
        BOOL full_utt_process_raw_false = FALSE;
        
        if(self.processSpeechLocally) {
            
            if (ps_start_utt(pocketSphinxDecoder, NULL) < 0) { // Data has been received and recognition is starting.
                if(openears_logging == 1) NSLog(@"ps_start_utt() failed");
                [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];

            }
            

            
            ps_process_raw(pocketSphinxDecoder, audioDeviceBuffer, speechData, no_search_false, full_utt_process_raw_false); // Process the data.
		
        }

		if(openears_logging == 1) NSLog(@"Speech detected...");
        
        if(self.outputAudio == TRUE && speechData > 0) [self availableBuffer:audioDeviceBuffer withLength:speechData * 2];
                
        [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidDetectSpeech" withOptionalObjects:nil andKeys:nil];

		// Forward to OpenEarsEventsObserver than speech has been detected.
		
		timestamp = continuousListener->read_ts;
		
		if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
		
        for (;;) { // An inner loop in which the received speech will be decoded up to the point of a silence longer than a second.
			
            if(audioDevice->recordData == 0) { // If we have looped back here in a suspended state, we exit.
                break;
            }
            
			if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.

            if ((speechData = cont_ad_read(continuousListener, audioDeviceBuffer, maximumAndBufferIndices)) < 0) { // Read the available data.
				

				if(openears_logging == 1) NSLog(@"cont_ad_read failed");
                
                [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
                	
			}
			
			if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
			
            if (speechData == 0) { // No speech data, could be the end of a statement if it's been more than a second since the last received speech.

                if ((continuousListener->read_ts - timestamp) > (kSamplesPerSecond * self.secondsOfSilenceToDetect)) {

                    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidDetectFinishedSpeech" withOptionalObjects:nil andKeys:nil];
                    
                    break;
				}
            } else { // New speech data.
				
				timestamp = continuousListener->read_ts;
            }
			
			if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.

			// Decode the data.
            
            if(self.processSpeechLocally) {
                remainingSpeechData = ps_process_raw(pocketSphinxDecoder, audioDeviceBuffer, speechData, no_search_false, full_utt_process_raw_false);

            }
            
            if(self.outputAudio == TRUE && speechData > 0) [self availableBuffer:audioDeviceBuffer withLength:speechData * 2];
  
            if ((remainingSpeechData == 0) && (speechData == 0)) { // If nothing more to be done for now, sleep.
				usleep(5000);
				if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
			}
			
			if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
        }
		
		if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.

		audioDevice->endingLoop = TRUE;
		int i;
		for ( i = 0; i < 10; i++ ) {
			readBufferContents(audioDevice, audioDeviceBuffer, maximumAndBufferIndices); // Make several attempts to read anything remaining in the buffer.
		}
		
        stopRecording(audioDevice); // Stop recording.
        audioDevice->endingLoop = FALSE;

        cont_ad_reset(continuousListener); // Reset the continuous module.
		
		if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.

		if(openears_logging == 1) NSLog(@"Processing speech, please wait...");
		
        
        if(self.processSpeechLocally) {

            ps_end_utt(pocketSphinxDecoder); // The utterance is ended
            
            if(audioDevice->recordData == 1) { // If we are suspended we don't want to get a hypothesis, just to return to the top of the loop ASAP.
            
                hypothesis = ps_get_hyp(pocketSphinxDecoder, &recognitionScore, &utteranceID); // Return the hypothesis.

                int32 probability = ps_get_prob(pocketSphinxDecoder, &utteranceID);
                
                if(hypothesis == NULL) { // We don't pass a truly null hyp through here because we can't use it to initialize an NSString from a UTF8 string. If we have received a null hyp we convert it to a zero-length string.
                    hypothesis = "";
                }
                
                NSString *hypothesisString = nil;
                
                if(returner == 0) {

                    NSMutableString *builtUpHypString = [[NSMutableString alloc] init];

                    NSArray *array = [[NSString stringWithFormat:@"%s",hypothesis] componentsSeparatedByString:@" "];

                    for(NSString *string in array) {
                        if([string rangeOfString:@"___"].location == NSNotFound) {
                            [builtUpHypString appendString:[NSString stringWithFormat:@"%@ ",string]];
                        }
                    }

                    
                    if([builtUpHypString length] >= 1) {

                        NSString *finalString = [builtUpHypString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        
                        if([finalString length] > 0) {
                             hypothesisString = [[NSString alloc] initWithString:[finalString copy]];

                        } else {
                         hypothesisString = [[NSString alloc] initWithString:@" "];  
                        }

                    
                    } else {
                        hypothesisString = [[NSString alloc] initWithString:@" "]; 

                        
                    }
                    [builtUpHypString release];
                    
                } else {
                    hypothesisString = [[NSString alloc] initWithUTF8String:hypothesis];
                }

                if(openears_logging == 1) NSLog(@"Pocketsphinx heard \"%@\" with a score of (%d) and an utterance ID of %s.", hypothesisString, probability, utteranceID);
                
                NSString *probabilityString = [[NSString alloc] initWithFormat:@"%d",probability];
                NSString *uttidString = [[NSString alloc] initWithFormat:@"%s",utteranceID];
                NSArray *hypothesisObjectsArray = [[NSArray alloc] initWithObjects:hypothesisString,probabilityString,uttidString,nil];
                NSArray *hypothesisKeysArray = [[NSArray alloc] initWithObjects:@"Hypothesis",@"RecognitionScore",@"UtteranceID",nil];
                
                if(self.returnNullHypotheses == TRUE) { // We have been asked to return all null hyps
                    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidReceiveHypothesis" withOptionalObjects:hypothesisObjectsArray andKeys:hypothesisKeysArray]; 
                } else if(([hypothesisString length] > 0) && ([hypothesisString isEqualToString:@" "] == FALSE)) { // We haven't been asked to return all null hyps but this hyp isn't null

                    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidReceiveHypothesis" withOptionalObjects:hypothesisObjectsArray andKeys:hypothesisKeysArray]; 

                } else {
                    if(openears_logging == 1) NSLog(@"Hypothesis was null so we aren't returning it. If you want null hypotheses to also be returned, set PocketsphinxController's property returnNullHypotheses to TRUE before starting PocketsphinxController."); // Hyp is null, don't return.
                }

                [hypothesisObjectsArray release];
                [hypothesisKeysArray release];
                [hypothesisString release];
                [probabilityString release];
                [uttidString release];

                if(self.returnNbest == TRUE) { // Let's get n-best if needed
                    
                    [self getNbestForDecoder:pocketSphinxDecoder withHypothesis:hypothesis andRecognitionScore:recognitionScore];
                }
                               
            }
        
        }

		if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
		
        if (startRecording(audioDevice) < 0) { // Start over.
			if(openears_logging == 1) NSLog(@"startRecording failed");
            
            [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
		}
		
		if(self.exitListeningLoop == 1) break; // Break if we're trying to exit the loop.
        
    }
   
     if(!self.pathToTestFile || ([self.pathToTestFile length] <= 10)) { // We don't do smart cmn when testing
         [self finalizeCmn:MFCC2FLOAT(pocketSphinxDecoder->acmod->fcb->cmn_struct->cmn_mean[0]) atRoute:audioDevice->currentRoute forAcousticModelAtPath:acousticModelPath]; // If we have a cmn value here at the end, it is always going to be a better value for this particular device, user and route than the naive init value, so we will save it for the next session run with this route and acoustic model and use it as the init value
     }
	self.inMainRecognitionLoop = FALSE; // We broke out of the loop.
	self.exitListeningLoop = 0; // We don't want to prompt further exiting attempts since we're out.
    
	stopRecording(audioDevice); // Stop recording if necessary.
    cont_ad_close(continuousListener); // Close the continuous module.

    
    if(self.processSpeechLocally) {
        ps_free(pocketSphinxDecoder); // Free the decoder.
    }
    
    closeAudioDevice(audioDevice); // Close the device, i.e. stop and dispose of the Audio Unit.

	if(openears_logging == 1) NSLog(@"No longer listening.");	
	
    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidStopListening" withOptionalObjects:nil andKeys:nil];
    
    if ( [delegate respondsToSelector:@selector(listeningLoopHasEnded)] ) {	
        
        [delegate listeningLoopHasEnded];
    }
}

- (void) listeningLoopHasEnded {}

- (void) getNbestForDecoder:(ps_decoder_t *)pocketSphinxDecoder withHypothesis:(char const *)hypothesis andRecognitionScore:(int32)recognitionScore {
    
    NSMutableArray *nbestMutableArray = [[NSMutableArray alloc] init];
    
    ps_nbest_t *nbest = ps_nbest(pocketSphinxDecoder, 0, -1, NULL, NULL);
    
    ps_nbest_t *next = NULL;
    
    for (int i=0; i < self.nBestNumber; i++) {
        next = ps_nbest_next(nbest);
        if (next) {
            
            hypothesis = ps_nbest_hyp(nbest, &recognitionScore);
            //                fprintf(fh, "%s %dn", hypothesis, recognitionScore);
            if(hypothesis == NULL) {
                hypothesis = "";
            }
            
            NSString *hypothesisString = [[NSString alloc] initWithUTF8String:hypothesis];
            
            [nbestMutableArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:hypothesisString,[NSNumber numberWithInt:recognitionScore],nil] forKeys:[NSArray arrayWithObjects:@"Hypothesis",@"Score",nil]]];
            
            //                
            //                for (seg = ps_nbest_seg(nbest, &recognitionScore); seg; seg = ps_seg_next(seg)) { // Probably not needed by most developers.
            //
            //                    char const *word;
            //                    int sf, ef;
            //
            //                    word = ps_seg_word(seg);
            //                    ps_seg_frames(seg, &sf, &ef);
            //                    printf("%s %d %d\n", word, sf, ef);
            //                }
            
            [hypothesisString release];
            
        } else {
            
            break;
        }
    }
    
    if (next) {
        ps_nbest_free(nbest);
    }
    NSArray *nBesthypothesisObjectsArray = [[NSArray alloc] initWithObjects:nbestMutableArray,nil];
    NSArray *nBesthypothesisKeysArray = [[NSArray alloc] initWithObjects:@"NbestHypothesisArray",nil];
    
    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidReceiveNbestHypothesisArray" withOptionalObjects:(NSArray *)nBesthypothesisObjectsArray andKeys:(NSArray *)nBesthypothesisKeysArray];
    
    [nBesthypothesisObjectsArray release];
    [nBesthypothesisKeysArray release];
    
    [nbestMutableArray release];
}

- (void) runRecognitionOnWavFileAtPath:(NSString *)wavPath usingLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF { // Listen to a single recording which already exists.
	
    [self checkWhetherJSGFSettingOf:languageModelIsJSGF LooksCorrectForThisFilename:languageModelPath];
    
    static ps_decoder_t *pocketSphinxDecoder; // The Pocketsphinx decoder which will perform the actual speech recognition on recorded speech.
    FILE *err_set_logfp(FILE *logfp); // This function will allow us to make Pocketsphinx run quietly.

	int32 recognitionScore;
    char const *hypothesis;
    char const *utteranceID;
    
if(verbose_pocketsphinx == 0) {
	err_set_logfp(NULL); // If verbose_pocketsphinx isn't defined, this will quiet the output from Pocketsphinx.
}

    CommandArray *commandArrayModel = [[CommandArray alloc] init];
	NSArray *commandArray = [commandArrayModel commandArrayForlanguageModel:languageModelPath dictionaryPath:dictionaryPath acousticModelPath:acousticModelPath isJSGF:languageModelIsJSGF];
	
	char* argv[[commandArray count]]; // We're simulating the command-line run arguments for Pocketsphinx.
	
    argv[1] = (char *)"";
    
	for (int i = 0; i < [commandArray count]; i++ ) { // Grab all the set arguments.
        
		char *argument = const_cast<char*> ([[commandArray objectAtIndex:i]UTF8String]);
		argv[i] = argument;
	}
	
	arg_t cont_args_def[] = { // Grab any extra arguments.
		POCKETSPHINX_OPTIONS,
		{ "-argfile", ARG_STRING, NULL, "Argument file giving extra arguments." },
		CMDLN_EMPTY_OPTION
	};
	
	cmd_ln_t *configuration; // The Pocketsphinx run configuration.
	
    if ([commandArray count] == 2) { // Fail if there aren't really any arguments.
		if(openears_logging == 1) NSLog(@"Initial Pocketsphinx command failed because there aren't any arguments in the command");
        
           [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
		
        configuration = cmd_ln_parse_file_r(NULL, cont_args_def, argv[1], TRUE);
    }  else { // Set the Pocketsphinx run configuration to the selected arguments and values.
        configuration = cmd_ln_parse_r(NULL, cont_args_def, [commandArray count], argv, FALSE);
    }
    
    pocketSphinxDecoder = ps_init(configuration); // Initialize the decoder.
	
    if (ps_start_utt(pocketSphinxDecoder, NULL) < 0) { // Data has been received and recognition is starting.
        if(openears_logging == 1) NSLog(@"ps_start_utt() failed");
        [self performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
    }
    
    BOOL no_search_false = FALSE; // The crashing bug from this in 0.6.1 appears to be fixed now.
    BOOL full_utt_process_raw_false = FALSE;
    
    NSData *originalWavData = [NSData dataWithContentsOfFile:wavPath];

    NSData *wavData = [originalWavData subdataWithRange:NSMakeRange(44, [originalWavData length]-44)];

    NSUInteger dataLength = [wavData length];
    SInt16 *wavSamples = (SInt16*)malloc(dataLength);
    memcpy(wavSamples, [wavData bytes], dataLength);

    ps_process_raw(pocketSphinxDecoder, wavSamples, dataLength /2, no_search_false, full_utt_process_raw_false); // Process the data.
    


    ps_end_utt(pocketSphinxDecoder); // The utterance is ended,
    free(wavSamples);
    hypothesis = ps_get_hyp(pocketSphinxDecoder, &recognitionScore, &utteranceID); // Return the hypothesis.
    int32 probability = ps_get_prob(pocketSphinxDecoder, &utteranceID);
    
    if(hypothesis == NULL) { // We don't pass a truly null hyp through here because we can't use it to initialize an NSString from a UTF8 string. If we have received a null hyp we convert it to a zero-length string.
        hypothesis = "";
    }
    
    if(openears_logging == 1) NSLog(@"Pocketsphinx heard \"%s\" with a score of (%d) and an utterance ID of %s.", hypothesis, probability, utteranceID);
    
    NSString *hypothesisString = [[NSString alloc] initWithUTF8String:hypothesis];
    NSString *probabilityString = [[NSString alloc] initWithFormat:@"%d",probability];
    NSString *uttidString = [[NSString alloc] initWithFormat:@"%s",utteranceID];
    NSArray *hypothesisObjectsArray = [[NSArray alloc] initWithObjects:hypothesisString,probabilityString,uttidString,nil];
    NSArray *hypothesisKeysArray = [[NSArray alloc] initWithObjects:@"Hypothesis",@"RecognitionScore",@"UtteranceID",nil];
    
    [self performOpenEarsNotificationOnMainThread:@"PocketsphinxDidReceiveHypothesis" withOptionalObjects:hypothesisObjectsArray andKeys:hypothesisKeysArray];
    
    [hypothesisObjectsArray release];
    [hypothesisKeysArray release];
    [hypothesisString release];
    [probabilityString release];
    [uttidString release];
    
    if(self.returnNbest == TRUE) { // Let's get n-best if needed
        
        [self getNbestForDecoder:pocketSphinxDecoder withHypothesis:hypothesis andRecognitionScore:recognitionScore];
    }
    
    cmd_ln_free_r(configuration);
    ps_free(pocketSphinxDecoder); // Free the decoder.
    [commandArrayModel release];
    
}


@end
