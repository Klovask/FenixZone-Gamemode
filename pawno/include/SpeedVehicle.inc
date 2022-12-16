 
/*
Version: 0.2
Author: Milanosie
Last Updated: 08-08-2012
Copyright: Milanosie
*/
 
/*=========================Changelog=========================*/
 
 
 
 
 
 
 
 
/*=========================Changelog=========================*/
#include <a_samp>
 
 
 
/*=========================Variables=========================*/
 
new P_Frozen[MAX_PLAYERS];
 
 
/*=========================Defines=========================*/
 
#define kmh 1
#define mph 2
 
#define far 0xF5D5E2FF
#define medium 0xF2B6CEFF
#define close 0xF57FAEFF
 
#define Model_Plane 1
#define Model_Heli 2
#define Model_Boat 3
#define Model_Car 4
#define Model_Bike 5
#define Model_Bicycle 6
#define Model_Unique 7
 
/*=========================Forwards=========================*/
 
forward GetVehicleSpeed(vehicleid);
forward GetClosestVehicleFromPoint(Float:x, Float:y, Float:z);
forward GetClosestVehicleFromPlayer(playerid);
forward GetClosestPlayerFromPlayer(playerid);
forward GetClosestPlayerFromPoint(Float:x, Float:y, Float:z);
forward LocalChat(playerid, Float:range, text[]);
forward GetVehicleType(vehicleid);
 
forward ToggleVehicleEngine(vehicleid);
forward StopVehicleEngine(vehicleid);
forward StartVehicleEngine(vehicleid);
forward Freeze(playerid);
forward Unfreeze(playerid);
forward TogFreeze(playerid);
forward SetVehicleSpeed(vehicleid, Float:speed);
 
/*=========================Callbacks=========================*/
 
public GetVehicleSpeed(vehicleid)
{
        new
                Float:x_speed, Float:y_speed, Float:z_speed, Float:speedf, speed;
 
 
        GetVehicleVelocity(vehicleid,x_speed,y_speed,z_speed);
        speedf = floatsqroot(((x_speed*x_speed)+(y_speed*y_speed))+(z_speed*z_speed)) * 187.666667;
        speed = floatround(speedf,floatround_round);
        return speed;
}
 
 
 
 
public GetClosestVehicleFromPoint(Float:x, Float:y, Float:z)
{
        new Float:dis = 99999999.0;
        new veh = -1;
        for(new i = 1; i < MAX_VEHICLES; i++)
        {
            new Float:distance = GetVehicleDistanceFromPoint(i, x, y, z);
            if(distance < dis)
            {
                dis = distance;
                veh = i;
                }
        }
        return veh;
}
 
 
public GetClosestVehicleFromPlayer(playerid)
{
        new Float:dis = 99999999.0;
        new veh = -1;
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        for(new i = 1; i < MAX_VEHICLES; i++)
        {
            new Float:distance = GetVehicleDistanceFromPoint(i, x, y, z);
            if(distance < dis)
            {
                dis = distance;
                veh = i;
                }
        }
        return veh;
}
 
 
 
 
 
 
 
 
 
public GetClosestPlayerFromPoint(Float:x, Float:y, Float:z)
{
        new Float:dis = 99999999.0;
        new veh = -1;
        for(new i = 1; i < MAX_PLAYERS; i++)
        {
            new Float:distance = GetPlayerDistanceFromPoint(i, x, y, z);
            if(distance < dis)
            {
                dis = distance;
                veh = i;
                }
        }
        return veh;
}
 
 
public GetClosestPlayerFromPlayer(playerid)
{
        new Float:dis = 99999999.0;
        new veh = -1;
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        for(new i = 1; i <= MAX_PLAYERS; i++)
        {
            new Float:distance = GetPlayerDistanceFromPoint(playerid, x, y, z);
            if(distance < dis)
            {
                dis = distance;
                veh = i;
                }
        }
        return veh;
}
 
 
public LocalChat(playerid, Float:range, text[])
{
        new vw = GetPlayerVirtualWorld(playerid);
        new int = GetPlayerInterior(playerid);
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        for(new i = 0; i <= MAX_PLAYERS; i++)
        {
            if(GetPlayerVirtualWorld(i) == vw)
            {
                if(GetPlayerInterior(i) == int)
                {
                    if(IsPlayerInRangeOfPoint(i, range / 3, x, y, z))
                    {
                        SendClientMessage(i, close, text);
                                }
                    else if(IsPlayerInRangeOfPoint(i, range / 2, x, y, z))
                    {
                        SendClientMessage(i, medium, text);
                                }
                    else if(IsPlayerInRangeOfPoint(i, range, x, y, z))
                    {
                        SendClientMessage(i, far, text);
                                }
                        }
                }
        }
        return 1;
}
 
 
 
public GetVehicleType(vehicleid)
{
        new m = GetVehicleModel(vehicleid);
        if(m == 592|| m == 577|| m == 511|| m == 512|| m == 593|| m == 520|| m == 553|| m == 476|| m == 519|| m == 460|| m == 513) return Model_Plane;
        else if(m == 548|| m == 425|| m == 417|| m == 487|| m == 488|| m == 497|| m == 563|| m == 447|| m == 469) return Model_Heli;
        else if(m == 472|| m == 473|| m == 493|| m == 595|| m == 484|| m == 430|| m == 453|| m == 452|| m == 446|| m == 454) return Model_Boat;
        else if(m == 509|| m == 481|| m == 510) return Model_Bicycle;
        else if(m == 462|| m == 448|| m == 581|| m == 522|| m == 461|| m == 521|| m == 523|| m == 463|| m == 586|| m == 468|| m == 471) return Model_Bike;
        else if(m == 406|| m == 435|| m == 411|| m == 449|| m == 450|| m == 464|| m == 465|| m == 501|| m == 537|| m == 538|| m == 539|| m == 564|| m == 569|| m == 570|| m == 584|| m == 590|| m == 591|| m == 594|| m == 606|| m == 607|| m == 608|| m == 610|| m == 611) return Model_Unique;
        else return Model_Car;
}
 
 
public ToggleVehicleEngine(vehicleid)
{
        new engine, lights, alarm, doors, bonnet, boot, objective;
        GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
        if(engine)
        {
            SetVehicleParamsEx(vehicleid,false,lights,alarm,doors,bonnet,boot,objective);
        }
        else
        {
            SetVehicleParamsEx(vehicleid,true,lights,alarm,doors,bonnet,boot,objective);
        }
        return 1;
}
 
public StartVehicleEngine(vehicleid)
{
        new engine, lights, alarm, doors, bonnet, boot, objective;
        GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
        SetVehicleParamsEx(vehicleid,true,lights,alarm,doors,bonnet,boot,objective);
        return 1;
}
 
public StopVehicleEngine(vehicleid)
{
        new engine, lights, alarm, doors, bonnet, boot, objective;
        GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
        SetVehicleParamsEx(vehicleid,false,lights,alarm,doors,bonnet,boot,objective);
        return 1;
}
 
 
 
public Freeze(playerid)
{
        TogglePlayerControllable(playerid, 0);
        P_Frozen[playerid] = 1;
        return 1;
}
 
 
public Unfreeze(playerid)
{
        TogglePlayerControllable(playerid, 1);
        P_Frozen[playerid] = 0;
        return 1;
}
 
public TogFreeze(playerid)
{
        if(P_Frozen[playerid] == 1)
        {
                TogglePlayerControllable(playerid, 1);
                P_Frozen[playerid] = 0;
        }
        else
        {
                TogglePlayerControllable(playerid, 0);
                P_Frozen[playerid] = 1;
        }
        return 1;
}
 
 
 
public SetVehicleSpeed(vehicleid, Float:speed)
{
        if(speed != -1)
        {
                new Float:px,   Float:py,       Float:pz,       Float:pvx,      Float:pvy,      Float:pvz, Float:fl;
                GetVehiclePos(vehicleid, px,py, pz);
                GetVehicleVelocity(vehicleid, pvx, pvy, pvz);
                fl = floatsqroot((pvx * pvx) + (pvy * pvy) + (pvz * pvz));
                pvx = (pvx / fl) * (speed * 0.00475);
                pvy = (pvy / fl) * (speed * 0.00475);
                pvz = (pvz / fl) * (speed * 0.00475);
                SetVehicleVelocity(vehicleid, pvx, pvy, pvz);
        }
        return 1;
}