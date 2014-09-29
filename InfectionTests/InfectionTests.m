//
//  InfectionTests.m
//  InfectionTests
//
//  Created by Samuel E. Giddins on 9/24/14.
//  Copyright (c) 2014 Samuel E. Giddins. All rights reserved.
//

#import "User.h"

#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

SpecBegin(User)
    describe(@"Examples", ^{
    static RLMRealm *realm;
    static User *a, *b, *c;
        beforeEach(^{
            [RLMRealm useInMemoryDefaultRealm];
            realm = [RLMRealm defaultRealm];
        });
        
        afterEach(^{
            realm = nil;
            a = nil;
            b = nil;
            c = nil;
        });
        
        describe(@"three unconnected users", ^{
            beforeEach(^{
                [realm transactionWithBlock:^{
                    a = [User createInRealm:realm withObject:@{@"userID":@"a", @"infected":@NO}];
                    b = [User createInRealm:realm withObject:@{@"userID":@"b", @"infected":@NO}];
                    c = [User createInRealm:realm withObject:@{@"userID":@"c", @"infected":@NO}];
                }];
            });
            
            it(@"totally infects only one user", ^{
                [User totalInfection:a];
                expect(a.infected).to.beTruthy();
                expect(b.infected).to.beFalsy();
                expect(c.infected).to.beFalsy();
            });
            
            it(@"limited infects all users", ^{
                [User limitedInfection:3 inRealm:realm];
                expect(a.infected).to.beTruthy();
                expect(b.infected).to.beTruthy();
                expect(c.infected).to.beTruthy();
            });
        });
        
        describe(@"three acyclic users", ^{
            beforeEach(^{
                [realm transactionWithBlock:^{
                    a = [User createInRealm:realm withObject:@{@"userID":@"a", @"infected" : @NO}];
                    b = [User createInRealm:realm withObject:@{@"userID":@"b", @"infected" : @NO}];
                    c = [User createInRealm:realm withObject:@{@"userID":@"c", @"infected" : @NO}];
                    [a addStudent:b];
                    [b addStudent:c];
                }];
            });
            
            for (char i = 'a'; i <= 'c'; i++) {
                it([NSString stringWithFormat:@"totally infects all users starting with %c", i], ^{
                    [User totalInfection:[User objectsInRealm:realm where:@"userID == %@", [NSString stringWithFormat:@"%c", i]].firstObject];
                    expect([User objectsInRealm:realm where:@"infected == NO"].count).to.equal(0);
                });
            }
        });
    });

    describe(@"Infection", ^{
    static RLMRealm *realm;
    beforeEach(^{
        realm = nil;
        [RLMRealm useInMemoryDefaultRealm];
        realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        for (NSInteger i = 0; i < 1000; i++) {
            User *user = [User createInRealm:realm withObject:@{
                                                               @"userID" : @(i).stringValue,
                                                               @"infected" : @NO
                                                               }];
            
            for (NSInteger j = 0; j < arc4random_uniform(20); j++) {
                [[User createInRealm:realm withObject:@{
                                                       @"userID" : [NSString stringWithFormat:@"%05ld%ld", (long)i, (long)j],
                                                       @"infected" : @NO
                                                       }] addCoach:user];
            }
        }
        [realm commitWriteTransaction];
    });
    
    it(@"returns the closed networks", ^{
        NSSet *networks = [User closedNetworksInRealm:realm];
        for (NSSet *network in networks) {
            for (NSSet *otherNetwork in networks) {
                if (network == otherNetwork) {
                    continue;
                }
                
                expect([network intersectsSet:otherNetwork]).to.beFalsy();
            }
        }
    });
    
    it(@"totally infects an entire network", ^{
        RLMArray *allUsers = [User allObjectsInRealm:realm];
        User *randomUser = [allUsers objectAtIndex:(u_int32_t)arc4random_uniform((u_int32_t)allUsers.count)];
        [User totalInfection:randomUser];
        for (NSSet *network in [User closedNetworksInRealm:realm]) {
            BOOL infectedNetwork = [network containsObject:randomUser];
            for (User *user in network) {
                expect(user.infected).to.equal(infectedNetwork);
            }
        }
    });
    
    for (long i = 0; i < 10; i++) {
        it([NSString stringWithFormat:@"partially infects - %ld", i], ^{
            [User limitedInfection:1000 inRealm:realm];
            NSInteger infectedCount = [User objectsInRealm:realm where:@"infected == YES"].count;
            expect(infectedCount).to.beGreaterThanOrEqualTo(1000);
            expect(infectedCount).to.beLessThanOrEqualTo(2000);
        });
    }
    });

SpecEnd