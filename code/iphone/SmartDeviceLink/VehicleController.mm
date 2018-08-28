//
//  VehicleController.mm
//  Doom
//
//  Created by Michael Crimando on 8/27/18.
//

#import "VehicleController.h"
#import "SmartDeviceLink.h"
#import "Doom-Swift.h"


bool vehicleControllerIsAvailable(){
    return ProxyManager.sharedManager.isVehicleDataSubscribed;
}

void vehicleControllerInput(ticcmd_t* cmd){
    
}
