//
//  User.h
//  Infection
//
//  Created by Samuel E. Giddins on 9/24/14.
//  Copyright (c) 2014 Samuel E. Giddins. All rights reserved.
//

#import <Realm/Realm.h>

RLM_ARRAY_TYPE(User);

@interface User : RLMObject

@property (nonatomic) NSString* userID;

@property (nonatomic) BOOL infected;

@property (nonatomic) RLMArray<User>* students;

@property (nonatomic) RLMArray<User>* coaches;

- (void)addStudent:(User*)student;
- (void)addCoach:(User*)coach;

- (NSSet*)recursiveConnectedUsers;

+ (NSSet*)closedNetworksInRealm:(RLMRealm*)realm;

+ (void)totalInfection:(User*)patientZero;

+ (void)limitedInfection:(NSInteger)target inRealm:(RLMRealm*)realm;

@end
