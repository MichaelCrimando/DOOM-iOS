//
//  VehicleController.swift
//  Doom
//
//  Created by Michael Crimando on 8/22/18.
//

import Foundation


private var controller: GCController? = nil
private var initialized: Bool = false
private var togglePause = false
enum weaponswitch_e : Int {
    case weapon_PREVIOUS = 0
    case weapon_NEXT = 1
}

private func HasAmmo(weaponType: Int) -> Bool {
    // Trivial case: you've always got fist
    if weaponType == wp_fist {
        return true
    }
    let player: player_t? = players[consoleplayer]
    if player?.weaponowned[weaponType] == nil {
        // Don't switch to an unowned weapon
        return false
    }
    var ammo: Int = -1
    switch weaponType {
    case wp_pistol:
        ammo = player?.ammo[am_clip] ?? 0
    case wp_shotgun:
        ammo = player?.ammo[am_shell] ?? 0
    case wp_chaingun:
        ammo = player?.ammo[am_clip] ?? 0
    case wp_missile:
        ammo = player?.ammo[am_misl] ?? 0
    case wp_plasma:
        ammo = player?.ammo[am_cell] ?? 0
    case wp_bfg:
        ammo = player?.ammo[am_cell] ?? 0
        if ammo < 40 {
            ammo = 0
        }
    case wp_supershotgun:
        ammo = player?.ammo[am_shell] ?? 0
        if ammo < 2 {
            ammo = 0
        }
    default:
        break
    }
    return ammo > 0
}

private func SwitchWeapon(direction: weaponswitch_e) -> Int {
    var index = players[consoleplayer].readyweapon
    if direction == WEAPON_PREVIOUS {
        index -= 1
        while !HasAmmo(index) {
            index -= 1
            if index < 0 {
                index = NUMWEAPONS - 1
            }
        }
    } else if direction == WEAPON_NEXT {
        index += 1
        while !HasAmmo(index) {
            index += 1
            if index >= NUMWEAPONS {
                index = 0
            }
        }
    }
    if index == weaponSelected {
        return wp_nochange
    }
    return index
}

private func setupPauseButtonHandler(ctrl: GCController?) {
    if ctrl != nil {
        ctrl?.controllerPausedHandler = { c in
            togglePause = true
        }
    }
}

/**
 Lazily initialze game controller on first request
 return true if controller is available
 */
func vehicleControllerIsAvailable() -> Bool {
    if !initialized {
        self.initVehicleController()
    }
    return controller
}

func vehicleControllerInput(cmd: ticcmd_t?) {
    if vehicleControllerIsAvailable() {
        // Perform standard gamepad updates
        let gamepad: GCExtendedGamepad? = controller.extendedGamepad
        cmd?.angleturn += (gamepad?.rightThumbstick.xAxis.value ?? 0.0) * -ROTATETHRESHOLD
        cmd?.forwardmove += (gamepad?.leftThumbstick.yAxis.value ?? 0.0) * TURBOTHRESHOLD
        cmd?.sidemove += (gamepad?.leftThumbstick.xAxis.value ?? 0.0) * TURBOTHRESHOLD
        if gamepad?.rightTrigger.isPressed ?? false {
            cmd?.buttons |= BT_ATTACK
        }
        if gamepad?.buttonA.isPressed ?? false {
            cmd?.buttons |= BT_USE
        }
        var newWeapon = wp_nochange
        // Switch weapons using X and Y buttons
        if gamepad?.buttonX.isPressed ?? false && players[consoleplayer].pendingweapon == wp_nochange {
            newWeapon = SwitchWeapon(WEAPON_PREVIOUS)
        }
        if gamepad?.buttonY.isPressed ?? false && players[consoleplayer].pendingweapon == wp_nochange {
            newWeapon = SwitchWeapon(WEAPON_NEXT)
        }
        // If we switched weapons, pass that info down to our frame cmd
        if newWeapon != wp_nochange {
            cmd?.buttons |= BT_CHANGE
            cmd?.buttons |= newWeapon << BT_WEAPONSHIFT
        }
        //        if(gamepad.dpad.left.pressed && players[consoleplayer].playerstate == PST_DEAD) {
        //            cmd->buttons |= BT_USE;
        //        }
        //
        //        if(gamepad.dpad.up.pressed && players[consoleplayer].playerstate == PST_DEAD) {
        //            cmd->buttons |= BT_SPECIAL;
        //        }
        //
        //        if(gamepad.dpad.right.pressed && players[consoleplayer].playerstate == PST_DEAD) {
        //            cmd->buttons |= BT_SPECIALMASK;
        //        }
        if togglePause {
            cmd?.buttons |= BT_SPECIAL | (BTS_PAUSE & BT_SPECIALMASK)
            togglePause = false
        }
    }
}
func initVehicleController(){
    let controllers = GCController.controllers()
        controller = nil
        //            }
        for i in 0..<controllers.count {
            if controllers[i].gamepad != nil || controllers[i].extendedGamepad != nil {
                controller = controllers[i]
            }
        }
        setupPauseButtonHandler(controller)
        // Register for controller connected/disconnected notifications
        let ns = NotificationCenter.default
        ns.addObserver(forName: .GCControllerDidConnect, object: nil, queue: OperationQueue.main, using: { note in
            if !controller {
                controller = GCController.controllers()[0]
                if !controller.gamepad() && controller.extendedGamepad == nil {
                    controller = nil
                }
                setupPauseButtonHandler(controller)
            }
        })
        ns.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: OperationQueue.main, using: { note in
            controller = nil
        })
        initialized = true
    // Only need to do this once
}
