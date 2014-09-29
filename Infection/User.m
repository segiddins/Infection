//
//  User.m
//  Infection
//
//  Created by Samuel E. Giddins on 9/24/14.
//  Copyright (c) 2014 Samuel E. Giddins. All rights reserved.
//

#import "User.h"

@implementation User

- (NSSet*)recursiveConnectedUsers
{
    NSMutableSet *users = [NSMutableSet set];
    [self recursivelyConnectUsers:users];
    return [NSSet setWithSet:users];
}

- (void)recursivelyConnectUsers:(NSMutableSet*)connectedUsers
{
    if ([connectedUsers containsObject:self]) {
        return;
    }

    [connectedUsers addObject:self];

    for (User* student in self.students) {
        [student recursivelyConnectUsers:connectedUsers];
    }

    for (User* coach in self.coaches) {
        [coach recursivelyConnectUsers:connectedUsers];
    }
}

- (void)addStudent:(User*)student
{
    [self.students addObject:student];
    [student.coaches addObject:self];
}

- (void)addCoach:(User*)coach
{
    [coach.students addObject:self];
    [self.coaches addObject:coach];
}

+ (NSSet*)closedNetworksInRealm:(RLMRealm*)realm
{
    NSMutableSet* networks = [NSMutableSet set];
    for (User* user in [self allObjectsInRealm:realm]) {
        BOOL inNetwork = NO;
        for (NSSet* network in networks) {
            if ([network containsObject:user]) {
                inNetwork = YES;
                break;
            }
        }
        if (inNetwork) {
            continue;
        }

        [networks addObject:[user recursiveConnectedUsers]];
    }

    return networks;
}

#pragma mark - Infection

+ (void)totalInfection:(User*)patientZero
{
    [patientZero.realm transactionWithBlock:^{
        patientZero.infected = YES;
        
        for (User* user in [patientZero recursiveConnectedUsers]) {
            user.infected = YES;
        }
    }];
}

+ (void)limitedInfection:(NSInteger)target inRealm:(RLMRealm*)realm
{
    [realm transactionWithBlock:^{
        NSInteger infectedCount = 0;
        NSArray* sortedNetworks = [[self closedNetworksInRealm:realm] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"@count" ascending:NO] ]];
        for (NSSet* network in sortedNetworks) {
            if (infectedCount >= target) {
                break;
            }
            
            limitedInfectionOfNetwork(network, target, &infectedCount);
        }
    }];
}

void limitedInfectionOfNetwork(NSSet* network, NSInteger target, NSInteger* infectionCount)
{
    NSArray* users = [[network allObjects] sortedArrayUsingComparator:^NSComparisonResult(User* obj1, User* obj2) {
        NSUInteger count1 = 0;
        NSUInteger count2 = 0;
        for (User *student in obj1.students) {
            if (student.infected) count1++;
        }
        for (User *student in obj2.students) {
            if (student.infected) count2++;
        }
        if (count1 == count2) return NSOrderedSame;
        else if (count1 < count2) return NSOrderedDescending;
        else return NSOrderedAscending;
    }];
    for (User* user in users) {
        if (*infectionCount >= target) {
            break;
        }

        [user limitedInfection:target count:infectionCount];
    }
}

- (void)limitedInfection:(NSInteger)target count:(NSInteger*)count
{
    if (*count >= target) {
        return;
    }
    
    if (!self.infected) {
        self.infected = YES;
        (*count)++;
    }

    for (User* user in self.students) {
        if (!user.infected) {
            user.infected = YES;
            (*count)++;
        }
    }
}

#pragma mark - RLMObject

+ (NSString*)primaryKey
{
    return NSStringFromSelector(@selector(userID));
}

@end
