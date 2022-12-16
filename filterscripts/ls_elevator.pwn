#include <a_samp>
#include "../include/gl_common.inc"

#define ELEVATOR_SPEED      (5.0)
#define DOORS_SPEED         (5.0)
#define ELEVATOR_WAIT_TIME  (5000)

#define DIALOG_ID           (874)

#define X_DOOR_CLOSED       (1786.627685)
#define X_DOOR_R_OPENED     (1785.027685)
#define X_DOOR_L_OPENED     (1788.227685)
#define GROUND_Z_COORD      (14.511476)
#define ELEVATOR_OFFSET     (0.059523)

static FloorNames[4][] =
{
	"Planta Baja",
	//"Piso: 1",
	//"Piso: 2",
	//"Piso: 3",
	//"Piso: 4",
	//"Piso: 5",
	//"Piso: 6",
	//"Piso: 7",
	//"Piso: 8",
	"Piso: 9",
	//"Piso: 10",
	//"Piso: 11",
	//"Piso: 12",
	//"Piso: 13",
	"Piso: 14",
	//"Piso: 15",
	//"Piso: 16",
	"Piso: 17"
	//"Piso: 18",
	//"Piso: 19",
	//"Piso: 20"
};

static Float:FloorZOffsets[4] =
{
    0.0,
    //8.5479,
    //13.99945,
    //19.45100,
    //24.90255,
    //30.35410,
    //35.80565,
    //41.25720,
    //46.70875,
    52.16030,
    //57.61185,
	//63.06340,
    //68.51495,
    //73.96650,
    79.41805,
    //84.86960,
    //90.32115,
    95.77270,
    //101.22425,
    //106.67580,
    //112.12735
};

new Obj_Elevator, Obj_ElevatorDoors[2],
	Obj_FloorDoors[4][2];

new Text3D:Label_Elevator, Text3D:Label_Floors[4];

#define ELEVATOR_STATE_IDLE     (0)
#define ELEVATOR_STATE_WAITING  (1)
#define ELEVATOR_STATE_MOVING   (2)

new ElevatorState,
	ElevatorFloor;

#define INVALID_FLOOR           (-1)

new ElevatorQueue[4],
	FloorRequestedBy[4];

new ElevatorBoostTimer;

forward CallElevator(playerid, floorid);
forward ShowElevatorDialog(playerid);

forward Elevator_Initialize();
forward Elevator_Destroy();

forward Elevator_OpenDoors();
forward Elevator_CloseDoors();
forward Floor_OpenDoors(floorid);
forward Floor_CloseDoors(floorid);

forward Elevator_MoveToFloor(floorid);
forward Elevator_Boost(floorid);
forward Elevator_TurnToIdle();

forward ReadNextFloorInQueue();
forward RemoveFirstQueueFloor();
forward AddFloorToQueue(floorid);
forward IsFloorInQueue(floorid);
forward ResetElevatorQueue();

forward DidPlayerRequestElevator(playerid);

forward Float:GetElevatorZCoordForFloor(floorid);
forward Float:GetDoorsZCoordForFloor(floorid);

public OnFilterScriptInit()
{
	ResetElevatorQueue();
	Elevator_Initialize();

	return 1;
}

public OnFilterScriptExit()
{
	Elevator_Destroy();

	return 1;
}

public OnObjectMoved(objectid)
{
    new Float:x, Float:y, Float:z;
	for(new i; i < sizeof(Obj_FloorDoors); i ++)
	{
		if(objectid == Obj_FloorDoors[i][0])
		{
		    GetObjectPos(Obj_FloorDoors[i][0], x, y, z);

		    if(x < X_DOOR_L_OPENED - 0.5)
		    {
				Elevator_MoveToFloor(ElevatorQueue[0]);
				RemoveFirstQueueFloor();
			}
		}
	}

	if(objectid == Obj_Elevator)
	{
	    KillTimer(ElevatorBoostTimer);

	    FloorRequestedBy[ElevatorFloor] = INVALID_PLAYER_ID;

	    Elevator_OpenDoors();
	    Floor_OpenDoors(ElevatorFloor);

	    GetObjectPos(Obj_Elevator, x, y, z);
	    Label_Elevator	= Create3DTextLabel("{FFFFFF}Precione {DBED15}'~k~~CONVERSATION_YES~'{FFFFFF} para usar o elevador.", 0xCCCCCCAA, 1784.9822, -1302.0426, z - 0.9, 4.0, 0, 1);

	    ElevatorState 	= ELEVATOR_STATE_WAITING;
	    SetTimer("Elevator_TurnToIdle", ELEVATOR_WAIT_TIME, 0);
	}

	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_ID)
    {
        if(!response)
            return 0;

        if(FloorRequestedBy[listitem] != INVALID_PLAYER_ID || IsFloorInQueue(listitem))
            GameTextForPlayer(playerid, "~r~El piso ya esta en la cola", 3500, 4);
		else if(DidPlayerRequestElevator(playerid))
		    GameTextForPlayer(playerid, "~r~Usted ya solicito el ascensor", 3500, 4);
		else
	        CallElevator(playerid, listitem);

		return 1;
    }

	return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(!IsPlayerInAnyVehicle(playerid) && (newkeys & KEY_YES) || (newkeys & KEY_SECONDARY_ATTACK))
	{
	    new Float:pos[3];
	    GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
	    if(pos[1] < -1301.4 && pos[1] > -1303.2417 && pos[0] < 1786.2131 && pos[0] > 1784.1555)
	        ShowElevatorDialog(playerid);
		else
		{
		    if(pos[1] > -1301.4 && pos[1] < -1299.1447 && pos[0] < 1785.6147 && pos[0] > 1781.9902)
		    {
				new i=3;
				while(pos[2] < GetDoorsZCoordForFloor(i) + 3.5 && i > 0)
				    i --;
				if(i == 0 && pos[2] < GetDoorsZCoordForFloor(0) + 2.0)
				    i = -1;
				if(i <= 2)
				{
					CallElevator(playerid, i + 1);
					GameTextForPlayer(playerid, "~r~Elevador llamado", 3500, 4);
				}
		    }
		}
	}

	return 1;
}

stock Elevator_Initialize()
{

	Obj_Elevator 			= CreateObject(18755, 1786.678100, -1303.459472, GROUND_Z_COORD + ELEVATOR_OFFSET, 0.000000, 0.000000, 270.000000);
	Obj_ElevatorDoors[0] 	= CreateObject(18757, X_DOOR_CLOSED, -1303.459472, GROUND_Z_COORD, 0.000000, 0.000000, 270.000000);
	Obj_ElevatorDoors[1] 	= CreateObject(18756, X_DOOR_CLOSED, -1303.459472, GROUND_Z_COORD, 0.000000, 0.000000, 270.000000);

	Label_Elevator          = Create3DTextLabel("{FFFFFF}Precione {DBED15}'~k~~CONVERSATION_YES~'{FFFFFF} para usar o elevador.", 0xCCCCCCAA, 1784.9822, -1302.0426, 13.6491, 4.0, 0, 1);

	new string[128],
		Float:z;

	for(new i; i < sizeof(Obj_FloorDoors); i ++)
	{
	    Obj_FloorDoors[i][0] 	= CreateObject(18757, X_DOOR_CLOSED, -1303.171142, GetDoorsZCoordForFloor(i), 0.000000, 0.000000, 270.000000);
		Obj_FloorDoors[i][1] 	= CreateObject(18756, X_DOOR_CLOSED, -1303.171142, GetDoorsZCoordForFloor(i), 0.000000, 0.000000, 270.000000);

		format(string, sizeof(string), "{009BE4}%s\n{FFFFFF}Precione {DBED15}'~k~~CONVERSATION_YES~'{FFFFFF} para usar o elevador.", FloorNames[i]);

		if(i == 0)
		    z = 13.4713;
		else
		    z = 13.4713 + 8.7396 + ((i-1) * 5.45155);

		Label_Floors[i]         = Create3DTextLabel(string, 0xCCCCCCAA, 1783.9799, -1300.7660, z, 10.5, 0, 1);
	}

	Floor_OpenDoors(0);
	Elevator_OpenDoors();

	return 1;
}

stock Elevator_Destroy()
{
	DestroyObject(Obj_Elevator);
	DestroyObject(Obj_ElevatorDoors[0]);
	DestroyObject(Obj_ElevatorDoors[1]);
	Delete3DTextLabel(Label_Elevator);

	for(new i; i < sizeof(Obj_FloorDoors); i ++)
	{
	    DestroyObject(Obj_FloorDoors[i][0]);
		DestroyObject(Obj_FloorDoors[i][1]);
		Delete3DTextLabel(Label_Floors[i]);
	}

	return 1;
}

stock Elevator_OpenDoors()
{
	new Float:x, Float:y, Float:z;

	GetObjectPos(Obj_ElevatorDoors[0], x, y, z);
	MoveObject(Obj_ElevatorDoors[0], X_DOOR_L_OPENED, y, z, DOORS_SPEED);
	MoveObject(Obj_ElevatorDoors[1], X_DOOR_R_OPENED, y, z, DOORS_SPEED);

	return 1;
}

stock Elevator_CloseDoors()
{
    if(ElevatorState == ELEVATOR_STATE_MOVING)
	    return 0;

    new Float:x, Float:y, Float:z;

	GetObjectPos(Obj_ElevatorDoors[0], x, y, z);
	MoveObject(Obj_ElevatorDoors[0], X_DOOR_CLOSED, y, z, DOORS_SPEED);
	MoveObject(Obj_ElevatorDoors[1], X_DOOR_CLOSED, y, z, DOORS_SPEED);

	return 1;
}

stock Floor_OpenDoors(floorid)
{
    MoveObject(Obj_FloorDoors[floorid][0], X_DOOR_L_OPENED, -1303.171142, GetDoorsZCoordForFloor(floorid), DOORS_SPEED);
	MoveObject(Obj_FloorDoors[floorid][1], X_DOOR_R_OPENED, -1303.171142, GetDoorsZCoordForFloor(floorid), DOORS_SPEED);

	PlaySoundForPlayersInRange(6401, 50.0, X_DOOR_CLOSED, -1303.171142, GetDoorsZCoordForFloor(floorid) + 5.0);

	return 1;
}

stock Floor_CloseDoors(floorid)
{
    MoveObject(Obj_FloorDoors[floorid][0], X_DOOR_CLOSED, -1303.171142, GetDoorsZCoordForFloor(floorid), DOORS_SPEED);
	MoveObject(Obj_FloorDoors[floorid][1], X_DOOR_CLOSED, -1303.171142, GetDoorsZCoordForFloor(floorid), DOORS_SPEED);

	PlaySoundForPlayersInRange(6401, 50.0, X_DOOR_CLOSED, -1303.171142, GetDoorsZCoordForFloor(floorid) + 5.0);

	return 1;
}

stock Elevator_MoveToFloor(floorid)
{
	ElevatorState = ELEVATOR_STATE_MOVING;
	ElevatorFloor = floorid;

	MoveObject(Obj_Elevator, 1786.678100, -1303.459472, GetElevatorZCoordForFloor(floorid), 0.25);
    MoveObject(Obj_ElevatorDoors[0], X_DOOR_CLOSED, -1303.459472, GetDoorsZCoordForFloor(floorid), 0.25);
    MoveObject(Obj_ElevatorDoors[1], X_DOOR_CLOSED, -1303.459472, GetDoorsZCoordForFloor(floorid), 0.25);
    Delete3DTextLabel(Label_Elevator);

	ElevatorBoostTimer = SetTimerEx("Elevator_Boost", 2000, 0, "i", floorid);

	return 1;
}

public Elevator_Boost(floorid)
{
	StopObject(Obj_Elevator);
	StopObject(Obj_ElevatorDoors[0]);
	StopObject(Obj_ElevatorDoors[1]);

	MoveObject(Obj_Elevator, 1786.678100, -1303.459472, GetElevatorZCoordForFloor(floorid), ELEVATOR_SPEED);
    MoveObject(Obj_ElevatorDoors[0], X_DOOR_CLOSED, -1303.459472, GetDoorsZCoordForFloor(floorid), ELEVATOR_SPEED);
    MoveObject(Obj_ElevatorDoors[1], X_DOOR_CLOSED, -1303.459472, GetDoorsZCoordForFloor(floorid), ELEVATOR_SPEED);

	return 1;
}

public Elevator_TurnToIdle()
{
	ElevatorState = ELEVATOR_STATE_IDLE;
	ReadNextFloorInQueue();

	return 1;
}

stock RemoveFirstQueueFloor()
{
	for(new i; i < sizeof(ElevatorQueue) - 1; i ++)
	    ElevatorQueue[i] = ElevatorQueue[i + 1];

	ElevatorQueue[sizeof(ElevatorQueue) - 1] = INVALID_FLOOR;

	return 1;
}

stock AddFloorToQueue(floorid)
{
	new slot = -1;
	for(new i; i < sizeof(ElevatorQueue); i ++)
	{
	    if(ElevatorQueue[i] == INVALID_FLOOR)
	    {
	        slot = i;
	        break;
	    }
	}

	if(slot != -1)
	{
	    ElevatorQueue[slot] = floorid;

	    if(ElevatorState == ELEVATOR_STATE_IDLE)
	        ReadNextFloorInQueue();

	    return 1;
	}

	return 0;
}

stock ResetElevatorQueue()
{
	for(new i; i < sizeof(ElevatorQueue); i ++)
	{
	    ElevatorQueue[i] 	= INVALID_FLOOR;
	    FloorRequestedBy[i] = INVALID_PLAYER_ID;
	}

	return 1;
}

stock IsFloorInQueue(floorid)
{
	for(new i; i < sizeof(ElevatorQueue); i ++)
	    if(ElevatorQueue[i] == floorid)
	        return 1;

	return 0;
}

stock ReadNextFloorInQueue()
{
	if(ElevatorState != ELEVATOR_STATE_IDLE || ElevatorQueue[0] == INVALID_FLOOR)
	    return 0;

	Elevator_CloseDoors();
	Floor_CloseDoors(ElevatorFloor);

	return 1;
}

stock DidPlayerRequestElevator(playerid)
{
	for(new i; i < sizeof(FloorRequestedBy); i ++)
	    if(FloorRequestedBy[i] == playerid)
	        return 1;

	return 0;
}

stock ShowElevatorDialog(playerid)
{
	new string[512];
	for(new i; i < sizeof(ElevatorQueue); i ++)
	{
	    if(FloorRequestedBy[i] != INVALID_PLAYER_ID)
	        strcat(string, "{FF0000}");

	    strcat(string, FloorNames[i]);
	    strcat(string, "\n");
	}

	ShowPlayerDialog(playerid, DIALOG_ID, DIALOG_STYLE_LIST, "Elevador", string, "Aceptar", "Cancelar");

	return 1;
}

stock CallElevator(playerid, floorid)
{
	if(FloorRequestedBy[floorid] != INVALID_PLAYER_ID || IsFloorInQueue(floorid))
	    return 0;

	FloorRequestedBy[floorid] = playerid;
	AddFloorToQueue(floorid);

	return 1;
}

stock Float:GetElevatorZCoordForFloor(floorid)
    return (GROUND_Z_COORD + FloorZOffsets[floorid] + ELEVATOR_OFFSET);

stock Float:GetDoorsZCoordForFloor(floorid)
	return (GROUND_Z_COORD + FloorZOffsets[floorid]);
