//
//  VehicleController.mm
//  Doom
//
//  Created by Michael Crimando on 8/27/18.
//  Basically this is the translator from vehicle data in swift to game controller in objc

#import "VehicleController.h"
#import "SmartDeviceLink.h"
#import "Doom-Swift.h"

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
        
        cmd->angleturn += ([NSNumber numberWithFloat:ProxyManager.sharedManager.steeringWheelAngle] * -ROTATETHRESHOLD);
        cmd->forwardmove += ([NSNumber numberWithFloat:ProxyManager.sharedManager.accelPedalPosition] * TURBOTHRESHOLD);
        //cmd->sidemove += (gamepad.leftThumbstick.xAxis.value * TURBOTHRESHOLD);
        
        if(ProxyManager.sharedManager.bodyData.driverDoorAjar) {
            cmd->buttons |= BT_ATTACK;
        }
        
//        if(gamepad.buttonA.pressed) {
//            cmd->buttons |= BT_USE;
//        }
        
        int newWeapon = wp_nochange;
        
        // Switch weapons using Passenger Door
        if(ProxyManager.sharedManager.bodyData.passengerDoorAjar && players[consoleplayer].pendingweapon == wp_nochange) {
            newWeapon = SwitchWeapon(WEAPON_PREVIOUS);
        }
        
//        if(gamepad.buttonY.pressed && players[consoleplayer].pendingweapon == wp_nochange) {
//            newWeapon = SwitchWeapon(WEAPON_NEXT);
//        }
        
        // If we switched weapons, pass that info down to our frame cmd
        if(newWeapon != wp_nochange) {
            cmd->buttons |= BT_CHANGE;
            cmd->buttons |= newWeapon << BT_WEAPONSHIFT;
        
    }
}
//There's no pausing in the car, that would be a distraction
//static bool togglePause = false;

