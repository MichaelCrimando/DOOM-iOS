//
//  VehicleController.m
//  DOOM
//
//  Created by Michael Crimando on 3/16/20.
//  Basically this is the translator from vehicle data in swift to game controller in objc

#import "VehicleController.h"
#import "SmartDeviceLink.h"
#if GAME_DOOM
#import "DOOM-Swift.h"
#elif GAME_DOOM2
#import "DOOM_II-Swift.h"
#elif GAME_FINALDOOM
#import "FInal_DOOM-Swift.h"
#else
#import "SIGIL-Swift.h"
#endif

typedef enum {
    WEAPON_PREVIOUS = 0,
    WEAPON_NEXT = 1,
}weaponswitch_e;


bool vehicleControllerIsAvailable(){
    return ProxyManager.sharedManager.isVehicleDataSubscribed;
}


void vehicleControllerInput(ticcmd_t* cmd){
    if(vehicleControllerIsAvailable()) {
        // Perform standard gamepad updates
        cmd->angleturn += (ProxyManager.sharedManager.steeringWheelAngle * ROTATETHRESHOLD);
        if(ProxyManager.sharedManager.isDriverBraking){
            cmd->forwardmove += (-1 * TURBOTHRESHOLD);
        } else {
            cmd->forwardmove += (ProxyManager.sharedManager.accelPedalPosition * TURBOTHRESHOLD);
        }

        
        //If door is closed, shoot
        if(![ProxyManager.sharedManager.bodyData.driverDoorAjar boolValue]) {
            cmd->buttons |= BT_ATTACK;
        }
        
//        if(gamepad.buttonA.pressed) {
//            cmd->buttons |= BT_USE;
//        }
        
        int newWeapon = wp_nochange;
        
        // Switch weapons using Passenger Door
//        if(ProxyManager.sharedManager.bodyData.passengerDoorAjar && players[consoleplayer].pendingweapon == wp_nochange) {
//            newWeapon = SwitchWeapon(weaponswi);
//        }
        
//        if(gamepad.buttonY.pressed && players[consoleplayer].pendingweapon == wp_nochange) {
//            newWeapon = SwitchWeapon(WEAPON_NEXT);
//        }
        
        // If we switched weapons, pass that info down to our frame cmd
        if(newWeapon != wp_nochange) {
            cmd->buttons |= BT_CHANGE;
            cmd->buttons |= newWeapon << BT_WEAPONSHIFT;
        }
    }
}
//There's no pausing in the car, that would be a distraction
//static bool togglePause = false;

