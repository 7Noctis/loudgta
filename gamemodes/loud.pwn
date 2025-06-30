#include <a_samp>
#include <../include/lib/sscanf2>
#include <../include/lib/dc_cmd>
#include <../include/lib/streamer>
#include <../include/lib/a_mysql>
main() return 1;

#include "../include/core/config.inc"

new carId[MAX_PLAYERS];

enum player_dialogs
{
	DIALOG_REGISTER,
	DIALOG_LOGIN,
	DIALOG_BUSINESS_ENTER,
	DIALOG_BUSINESS_INFO,
	DIALOG_BUSINESS_BUY,
	DIALOG_BUSINESS_GET,
	DIALOG_BUSINESS_MANAGE,
	DIALOG_PLAYER_MENU,
	DIALOG_PLAYER_CARS,
	DIALOG_PLAYER_CARID,
	DIALOG_SPAWNS,
	DIALOG_PLAYER_STATS,
	DIALOG_ORG_CREATE,
	DIALOG_ORG_NAME,
	DIALOG_TELEPORTS,
	DIALOG_FIRST_SPAWN
}

enum player_info
{
	pID,
	pName[MAX_PLAYER_NAME],
	pPassword[29],
	pKills,
	pDeaths,
	pMoney,
	pExp,
	pAdminLevel,
	pHouseID,
	bool: pLogged,
	bool: pInBusiness,
	pLastCarId,
	pSpawnPlace, // 0 -ls, 1 - sf, 2 - lv, 3 - all
	bool: isFirstSpawn
};

enum spawn_positions
{
	SPAWN_LS,
	SPAWN_SF,
	SPAWN_LV,
	SPAWN_ALL
};

enum business_info
{
	bID,
	bName[36],
	bOwner[MAX_PLAYER_NAME],
	bPrice,
	bInterior,
	bBudget,
	bPickup,
	bMapIcon,
	Text3D: b3DText,
	Float: bX,
	Float: bY,
	Float: bZ
};

enum org_info
{
	oId,
	oName[128],
	oMoney,
	oExp
};

new pInfo[MAX_PLAYERS][player_info];
new bInfo[MAX_BUSINESS][business_info];
new oInfo[MAX_ORGS][org_info];

new DB: db;

new MySQL:ConnectID;
new bool:IsConnected = false;

enum businessIntInfo
{
	bIntNumber,
	Float: bIntExitX,
	Float: bIntExitY,
	Float: bIntExitZ,
	Float: bIntBuyX,
	Float: bIntBuyY,
	Float: bIntBuyZ,
};

new businessInteriorsEats[][businessIntInfo] = {
	{10, 363.1548,-74.9414,1001.5078, 376.5422,-67.4359,1001.5078}, 		// burger shot interior
	{9, 364.9515,-11.2126,1001.8516, 368.1121,-6.0179,1001.8516}, 			// cluckung bell interior
	{5, 372.2982,-133.3474,1001.4922, 374.6626,-118.8026,1001.4995} 		// pizza stack interior
};

new const Float: spawnPositionsLS[][] = {
	{ 2094.0552,-1797.0798,13.3828,89.8904 }, // wellstackedpizza
	{ 2517.2747,-1667.5957,14.0607,86.1489 }, // groovestreet
	{ 1775.8157,-1915.1224,13.3863,267.9401 }, // unionstate
	{ 1890.7202,-1384.1154,13.5703,90.9614 }, // skatepark
	{ 2033.7520,-1196.2449,22.2615,270.4510 }, // prudpark
	{ 2430.3562,-1228.4436,25.1401,142.6947 }, // pigpenstripbar
	{ 1471.1033,-1711.5789,14.0469,180.5179 }, // meria
	{ 1128.9794,-1443.1372,15.7969,0.0761 }, // tradecenter
	{ 707.6633,-1426.1488,13.5391,359.6084 }, // jettylounge
	{ 300.0505,-1783.0389,4.4594,287.2084 }, // beach
	{ 378.6676,-2035.9153,7.8301,88.4567 }, // pierce
	{ 672.3755,-1262.4779,13.6250,87.1737 }, // tennis
	{ 1523.9824,-850.9188,65.6565,118.6538 }, // vinewood
	{ 2223.9583,-1157.0510,25.7630,2.2327 }, // jeffersonhotel
	{ 1944.6005,-2147.6152,13.5513,341.9770 }, // xxxshop
	{ 1594.9686,-2242.9548,13.5492,90.1738 } // airport
};

new const Float: spawnPositionsSF[][] = {
	{ -1976.9015,274.2065,35.1719,2.7448 }, // wangcars
	{ -2616.8315,1406.5533,7.1165,173.1202 } // jizzy
};

new const Float: spawnPositionsLV[][] = {
	{ 2101.3894,1260.0378,10.8203,149.5773 } // sfinks
};

new Float: spawnPositions[sizeof(spawnPositionsLS) + sizeof(spawnPositionsSF) + sizeof(spawnPositionsLV)][4];

CMD:changespawn(playerid, params[])
{
	ShowPlayerDialog(playerid, DIALOG_SPAWNS, DIALOG_STYLE_LIST, "Выбор спавна", "\
		Лос Сантос\n\
		Сан Фиерро\n\
		Лас Вентурас\n\
		Все", "Ок", "Не ок");
	return 1;
}

CMD:stats(playerid, params[])
{
	new str[80 + (11 * 5)];
	format(str, sizeof(str), "\
		ID: %d\n\
		Админ: %d\n\
		Убийства: %d\n\
		Смерти: %d\n\
		Деньги: %d\n\
		Опыт: %d", pInfo[playerid][pID], pInfo[playerid][pAdminLevel], pInfo[playerid][pKills], pInfo[playerid][pDeaths], pInfo[playerid][pMoney], pInfo[playerid][pExp]);

	ShowPlayerDialog(playerid, DIALOG_PLAYER_STATS, DIALOG_STYLE_MSGBOX, "Статистика", str, "Ок", "Отмена");
	return 1;
}

forward OnPlayerDataLoaded(playerid);
public OnPlayerDataLoaded(playerid)
{
	new rows;
    cache_get_row_count(rows);
 
    if(!rows)
    {
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Регистрация нового пользователя", "Введите пароль для регистрации нового аккаунта:", "Регистрация", "Выход");
    }
    else
    {
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль от аккаунта для того, чтоб продолжить игру:", "Вход", "Выход");
        cache_get_value_name(0, "Password", pInfo[playerid][pPassword], 28);
    }
}

forward UploadPlayerAccount(playerid);
public UploadPlayerAccount(playerid)
{
	cache_get_value_name_int(0, "Id", pInfo[playerid][pID]);
	cache_get_value_name_int(0, "Money", pInfo[playerid][pMoney]);
	cache_get_value_name_int(0, "Deaths", pInfo[playerid][pDeaths]);
	cache_get_value_name_int(0, "Kills", pInfo[playerid][pKills]);
	cache_get_value_name_int(0, "Experience", pInfo[playerid][pExp]);
	cache_get_value_name_int(0, "AdminLevel", pInfo[playerid][pAdminLevel]);
	cache_get_value_name_int(0, "LastCarId", pInfo[playerid][pLastCarId]);
	cache_get_value_name_int(0, "SpawnPlace", pInfo[playerid][pSpawnPlace]);

	GivePlayerMoney(playerid, pInfo[playerid][pMoney]);

	if(pInfo[playerid][pAdminLevel] > 0)
		SetPlayerColor(playerid, 0xFF0000FF);

	SendClientMessage(playerid, -1, "Вы прошли авторизацию.");

	new query[40 + MAX_PLAYER_NAME];
	mysql_format(ConnectID, query, sizeof(query), "UPDATE users SET IsOnline = 1 WHERE Id = %d", pInfo[playerid][pID]);
	mysql_tquery(ConnectID, query, "", "");
	return 1;
}

stock OnSpawnsArrayFill()
{
	new idx = 0;

    // Копируем spawnPositionsLS
    for(new i = 0; i < sizeof(spawnPositionsLS); i++)
    {
        for(new j = 0; j < 4; j++)
        {
            spawnPositions[idx][j] = spawnPositionsLS[i][j];
        }
        idx++;
    }

    // Копируем spawnPositionsSF
    for(new i = 0; i < sizeof(spawnPositionsSF); i++)
    {
        for(new j = 0; j < 4; j++)
        {
            spawnPositions[idx][j] = spawnPositionsSF[i][j];
        }
        idx++;
    }

    // Копируем spawnPositionsLV
    for(new i = 0; i < sizeof(spawnPositionsLV); i++)
    {
        for(new j = 0; j < 4; j++)
        {
            spawnPositions[idx][j] = spawnPositionsLV[i][j];
        }
        idx++;
    }
}

stock SavePlayer(playerid)
{
    new query[62 + 11 + 11 + 11];
	format(query, sizeof(query), "UPDATE users SET LastCarId = %d, SpawnPlace = %d, IsOnline = 0 WHERE Id = %d", pInfo[playerid][pLastCarId], pInfo[playerid][pSpawnPlace], pInfo[playerid][pID]);
    mysql_tquery(ConnectID, query, "", "");
    return 1;
}

public OnGameModeInit()
{
	ConnectID = mysql_connect("127.0.0.1", "root", "", "loudgta");

	if(mysql_errno(ConnectID) == 0)
		IsConnected = true;
	else
		SendRconCommand("password 100");

	OnSpawnsArrayFill();

	// LoadBusinesses();

	DisableInteriorEnterExits();
	UsePlayerPedAnims();
	EnableStuntBonusForAll(0);

	SendRconCommand("hostname "SERVER_NAME"");
	SendRconCommand("gamemodetext "SERVER_MODE"");
	SendRconCommand("language "SERVER_LANG"");
	SendRconCommand("weburl "SERVER_WEB"");

	SetWorldTime(6);
	return 1;
}

public OnGameModeExit()
{
	mysql_close(ConnectID);
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, pInfo[playerid][pName], MAX_PLAYER_NAME);
	SetPlayerColor(playerid, -1);

	for(new i; i < 25; i++) 
		SendClientMessage(playerid, -1, "");


	if(IsConnected)
	{
		new query[40 + MAX_PLAYER_NAME];
		mysql_format(ConnectID, query, sizeof(query), "SELECT * FROM users WHERE Login = '%s'", pInfo[playerid][pName]);
		mysql_tquery(ConnectID, query, "OnPlayerDataLoaded", "i", playerid);
	}
	else
	{
		SendClientMessage(playerid, -1, "у сервера проблемесы с бд пока");
	}
	
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SavePlayer(playerid);

	for(new player_info:e; e < player_info; e++)
	{
		pInfo[playerid][e] = EOS; 
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!pInfo[playerid][isFirstSpawn])
	{
		ShowPlayerDialog(playerid, DIALOG_FIRST_SPAWN, DIALOG_STYLE_MSGBOX, 
			"Разработка", 
			"Игровой режим находится в стадии разработки.\n\nВозможны неисправности в работе, если у вас есть жалобы или предложения, сообщите на почту разработчика goryunovlad@gmail.com.", 
			"Ок", 
			"Выход");

		pInfo[playerid][isFirstSpawn] = true;
	}

	if(pInfo[playerid][pSpawnPlace] == 0) // ls
	{
		new r = random(sizeof(spawnPositionsLS));

		SetPlayerPos(playerid, spawnPositionsLS[r][0], spawnPositionsLS[r][1], spawnPositionsLS[r][2]);
		SetPlayerFacingAngle(playerid, spawnPositionsLS[r][3]);
	}

	if(pInfo[playerid][pSpawnPlace] == 1) // sf
	{
		new r = random(sizeof(spawnPositionsSF));

		SetPlayerPos(playerid, spawnPositionsSF[r][0], spawnPositionsSF[r][1], spawnPositionsSF[r][2]);
		SetPlayerFacingAngle(playerid, spawnPositionsSF[r][3]);
	}

	if(pInfo[playerid][pSpawnPlace] == 2) // lv
	{
		new r = random(sizeof(spawnPositionsLV));

		SetPlayerPos(playerid, spawnPositionsLV[r][0], spawnPositionsLV[r][1], spawnPositionsLV[r][2]);
		SetPlayerFacingAngle(playerid, spawnPositionsLV[r][3]);
	}

	if(pInfo[playerid][pSpawnPlace] == 3) // all
	{
		new r = random(sizeof(spawnPositions));

		SetPlayerPos(playerid, spawnPositions[r][0], spawnPositions[r][1], spawnPositions[r][2]);
		SetPlayerFacingAngle(playerid, spawnPositions[r][3]);
	}

	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	SetPlayerHealth(playerid, 100.0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	pInfo[playerid][pDeaths]++;
	pInfo[killerid][pKills]++;
	pInfo[killerid][pExp] += 100;
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys == KEY_YES)
	{
		ShowPlayerDialog(playerid, DIALOG_PLAYER_MENU, DIALOG_STYLE_LIST, "Меню", "\
			Транспорт\n\
			Телепорты", "Ок", "Не ок");
	}

	if(newkeys == KEY_WALK)
	{
		if(IsPlayerInRangeOfPoint(playerid, 3.0, 1413.4626,-1702.0651,13.5395))
		{
			ShowPlayerDialog(playerid, DIALOG_ORG_CREATE, DIALOG_STYLE_LIST, "Бизнес", "Создать", "Ок", "Не ок");
		}
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_ORG_CREATE:
		{
			if(!response) return 0;

			if(listitem == 0)
			{
				ShowPlayerDialog(playerid, DIALOG_ORG_NAME, DIALOG_STYLE_INPUT, "Название", "Наименование биза", "Ок", "Не ок");
			}
		}

		case DIALOG_ORG_NAME:
		{
			if(!response) return 0;

			if(!strlen(inputtext)) return ShowPlayerDialog(playerid, DIALOG_ORG_NAME, DIALOG_STYLE_MSGBOX, "Название", "Наименование биза", "Ок", "Не ок");
			if(strlen(inputtext) < 3 || strlen(inputtext) > 96) return ShowPlayerDialog(playerid, DIALOG_ORG_NAME, DIALOG_STYLE_INPUT, "Название", "Наименование биза", "Ок", "Не ок");

			for(new i; i < strlen(inputtext); i++)
			{
				switch(inputtext[i])
				{
					case 'A'..'Z', 'a'..'z', '0'..'9': continue;
					default: return ShowPlayerDialog(playerid, DIALOG_ORG_NAME, DIALOG_STYLE_MSGBOX, "Название", "Наименование биза", "Ок", "Не ок");
				}
			}

			new query[62 + MAX_PLAYER_NAME - 2 - 2 + 30];
			mysql_format(ConnectID, query, sizeof(query), "INSERT INTO teams (Name) VALUES ('%s')", inputtext);
			mysql_tquery(ConnectID, query, "OnOrgCreate");

			SendClientMessage(playerid, -1, "Вы успешно создали оргу.");
		}

		case DIALOG_PLAYER_MENU:
		{
			if(!response) return 0;

			if(listitem == 0)
			{
				ShowPlayerDialog(playerid, DIALOG_PLAYER_CARS, DIALOG_STYLE_LIST, "Транспорт", "\
					Последний выбор\n\
					Ввести ID\n\
					Инфернус\n\
					Элегия\n\
					Туризмо", "Ок", "Не ок");
			}

			if(listitem == 1)
			{
				ShowPlayerDialog(playerid, DIALOG_TELEPORTS, DIALOG_STYLE_LIST, "Телепорты", "\
					> Лос Сантос\n\
					Грув Стрит\n\
					Доки\n\
					Аэропорт\n\
					Пирс\n\
					Колесо\n\
					Тенис\n\
					Вайнвуд\n\
					Центр\n\
					Мэрия\n\
					Скейтпарк\n\
					Отель Джеферсон\n\
					Станция Юнити\n\
					Обсерватория", "Ок", "Не ок");
				
			}
		}

		case DIALOG_TELEPORTS:
		{
			if(!response) return 0;

			if(listitem == 0) return 0;
			if(listitem == 1) SetPlayerPos(playerid, 2510.5278,-1669.3723,13.4670); // groove
			if(listitem == 2) SetPlayerPos(playerid, 2761.4063,-2393.4446,13.6328); // доки
			if(listitem == 3) SetPlayerPos(playerid, 1683.4183,-2244.7646,13.5431); // аэропорт
			if(listitem == 4) SetPlayerPos(playerid, 848.9660,-2009.4229,12.8672); // пирс
			if(listitem == 5) SetPlayerPos(playerid, 378.6031,-2037.5452,7.8301); // колесо
			if(listitem == 6) SetPlayerPos(playerid, 678.4388,-1260.7935,13.6013); // тенис
			if(listitem == 7) SetPlayerPos(playerid, 1478.1797,-743.5845,92.9847); // вайнвуд
			if(listitem == 8) SetPlayerPos(playerid, 1509.0387,-1328.3885,14.0271);// центр
			if(listitem == 9) SetPlayerPos(playerid, 1475.8754,-1722.3700,13.5469); // мэрия
			if(listitem == 10) SetPlayerPos(playerid, 1876.8812,-1377.4958,13.5618); // скейтпарк
			if(listitem == 11) SetPlayerPos(playerid, 2206.8823,-1159.6573,25.7287); // джеферсонотель
			if(listitem == 12) SetPlayerPos(playerid, 1765.5928,-1900.4380,13.5649); // юнитистейшн
			if(listitem == 13) SetPlayerPos(playerid, 1154.7061,-2012.7147,69.0078); // обсверватория

		}

		case DIALOG_PLAYER_CARID:
		{
			if(!response) return 0;

			new Float: x;
			new Float: y;
			new Float: z;
			
			GetPlayerPos(playerid, x, y, z);

			if(carId[playerid] != 0)
				DestroyVehicle(carId[playerid]);

			pInfo[playerid][pLastCarId] = strval(inputtext);
			
			carId[playerid] = CreateVehicle(pInfo[playerid][pLastCarId], x, y, z, -1, -1, -1, 0);
			
			PutPlayerInVehicle(playerid, carId[playerid], 0);
		}

		case DIALOG_PLAYER_CARS:
		{
			if(!response) return 0;

			if(listitem == 0)
			{
				if(pInfo[playerid][pLastCarId] != 0)
				{
					new Float: x;
					new Float: y;
					new Float: z;
					
					GetPlayerPos(playerid, x, y, z);

					if(carId[playerid] != 0)
						DestroyVehicle(carId[playerid]);
					
					carId[playerid] = CreateVehicle(pInfo[playerid][pLastCarId], x, y, z, -1, -1, -1, 0);
					
					PutPlayerInVehicle(playerid, carId[playerid], 0);
				}
				else
				{
					SendClientMessage(playerid, -1, "Вы еще не выбирали транспорт.");
				}
			}

			if(listitem == 1)
			{
				ShowPlayerDialog(playerid, DIALOG_PLAYER_CARID, DIALOG_STYLE_INPUT, "Вводите ID", "\
					давай ид пиши тачки", "Ок", "Не ок");
			}

			if(listitem == 2)
			{
				new Float: x;
				new Float: y;
				new Float: z;
				
				GetPlayerPos(playerid, x, y, z);

				if(carId[playerid] != 0)
					DestroyVehicle(carId[playerid]);

				pInfo[playerid][pLastCarId] = 411;
				
				carId[playerid] = CreateVehicle(pInfo[playerid][pLastCarId], x, y, z, -1, -1, -1, 0);
				
				PutPlayerInVehicle(playerid, carId[playerid], 0);
			}

			if(listitem == 3)
			{
				new Float: x;
				new Float: y;
				new Float: z;
				
				GetPlayerPos(playerid, x, y, z);

				if(carId[playerid] != 0)
					DestroyVehicle(carId[playerid]);

				pInfo[playerid][pLastCarId] = 562;
				
				carId[playerid] = CreateVehicle(pInfo[playerid][pLastCarId], x, y, z, -1, -1, -1, 0);
				
				PutPlayerInVehicle(playerid, carId[playerid], 0);
			}

			if(listitem == 4)
			{
				new Float: x;
				new Float: y;
				new Float: z;
				
				GetPlayerPos(playerid, x, y, z);

				if(carId[playerid] != 0)
					DestroyVehicle(carId[playerid]);

				pInfo[playerid][pLastCarId] = 451;
				
				carId[playerid] = CreateVehicle(pInfo[playerid][pLastCarId], x, y, z, -1, -1, -1, 0);
				
				PutPlayerInVehicle(playerid, carId[playerid], 0);
			}
		}

		case DIALOG_BUSINESS_MANAGE:
		{
			if(!response) return 0;

			if(listitem == 0)
			{
				new str[28 - 2 + 11];
				format(str, sizeof(str), "Бюджет вашего заведения: %d", bInfo[pInfo[playerid][pHouseID]][bBudget]);
				SendClientMessage(playerid, -1, str);
			}
		}

		case  DIALOG_BUSINESS_BUY:
		{
			if(!response) return 0;

			if(listitem == 0)
			{
				if(GetPlayerMoney(playerid) < 70) return SendClientMessage(playerid, -1, "У вас нет такой суммы.");

				bInfo[pInfo[playerid][pHouseID]][bBudget] += 70;

				new Float: health;
				GetPlayerHealth(playerid, health);
				if(health > 70)
				{
					SetPlayerHealth(playerid, 100.0);
				}
				else 
				{
					SetPlayerHealth(playerid, health + 30.0);
				}
			}

			if(listitem == 1)
			{
				if(GetPlayerMoney(playerid) < 120) return SendClientMessage(playerid, -1, "У вас нет такой суммы.");

				bInfo[pInfo[playerid][pHouseID]][bBudget] += 120;

				new Float: health;
				GetPlayerHealth(playerid, health);
				if(health > 50)
				{
					SetPlayerHealth(playerid, 100.0);
				}
				else 
				{
					SetPlayerHealth(playerid, health + 50.0);
				}
			}

			if(listitem == 2)
			{
				if(GetPlayerMoney(playerid) < 180) return SendClientMessage(playerid, -1, "У вас нет такой суммы.");

				bInfo[pInfo[playerid][pHouseID]][bBudget] += 180;

				new Float: health;
				GetPlayerHealth(playerid, health);
				if(health > 20)
				{
					SetPlayerHealth(playerid, 100.0);
				}
				else 
				{
					SetPlayerHealth(playerid, health + 80.0);
				}
			}
		}

		case DIALOG_BUSINESS_ENTER:
		{
			if(!response) return 0;
			if(listitem == 0)
			{
				if(!strcmp(bInfo[pInfo[playerid][pHouseID]][bOwner], pInfo[playerid][pName], false))
				{
					pInfo[playerid][pInBusiness] = true;
					SendClientMessage(playerid, -1, "Вы зашли в заведение, которое принадлежит вам.");
				}

				switch(bInfo[pInfo[playerid][pHouseID]][bInterior])
				{
					case 1: 
					{
						SetPlayerInterior(playerid, businessInteriorsEats[0][bIntNumber]);
						SetPlayerPos(playerid, businessInteriorsEats[0][bIntExitX], businessInteriorsEats[0][bIntExitY], businessInteriorsEats[0][bIntExitZ]);
						SetPlayerVirtualWorld(playerid, bInfo[pInfo[playerid][pHouseID]][bInterior] + 100);
					}
					case 2:
					{
						SetPlayerInterior(playerid, businessInteriorsEats[1][bIntNumber]);
						SetPlayerPos(playerid, businessInteriorsEats[1][bIntExitX], businessInteriorsEats[1][bIntExitY], businessInteriorsEats[1][bIntExitZ]);
						SetPlayerVirtualWorld(playerid, bInfo[pInfo[playerid][pHouseID]][bInterior] + 100);
					}
					case 3:
					{
						SetPlayerInterior(playerid, businessInteriorsEats[2][bIntNumber]);
						SetPlayerPos(playerid, businessInteriorsEats[2][bIntExitX], businessInteriorsEats[2][bIntExitY], businessInteriorsEats[2][bIntExitZ]);
						SetPlayerVirtualWorld(playerid, bInfo[pInfo[playerid][pHouseID]][bInterior] + 100);
					}
				}

			}
			if(listitem == 1)
			{
				new str[22 + MAX_PLAYER_NAME + 11];
				format(str, sizeof(str), "Price: %d \nOwner: %s", bInfo[pInfo[playerid][pHouseID]][bPrice], bInfo[pInfo[playerid][pHouseID]][bOwner]);
				ShowPlayerDialog(playerid, DIALOG_BUSINESS_INFO, DIALOG_STYLE_MSGBOX, bInfo[pInfo[playerid][pHouseID]][bName], str, "Ок", "Назад");
			}
			if(listitem == 2)
			{
				if(!strcmp(bInfo[pInfo[playerid][pHouseID]][bOwner], "-"))
				{
					if(GetPlayerMoney(playerid) < bInfo[pInfo[playerid][pHouseID]][bPrice]) return SendClientMessage(playerid, -1, "У вас недостаточно средств для покупки данного бизнеса.");
					ShowPlayerDialog(playerid, DIALOG_BUSINESS_GET, DIALOG_STYLE_MSGBOX, "Покупка бизнеса", "Вы уверены, что хотите приобрести данный бизнес?", "Продолжить", "Выход");
				}
				else
				{
					SendClientMessage(playerid, -1, "Извините, но у этого заведения уже есть владелец.");
				}
			}
		}

		case DIALOG_BUSINESS_GET:
		{
			if(!response) return SendClientMessage(playerid, -1, "Вы отказались от покупки бизнеса.");

			new str[56 + MAX_PLAYER_NAME + 1 + 11];
			format(str, sizeof(str), "UPDATE `Businesses` SET `Owner` = '%s' WHERE `ID` = '%d'", pInfo[playerid][pName], bInfo[pInfo[playerid][pHouseID]][bID]);
			db_query(db, str);

			bInfo[pInfo[playerid][pHouseID]][bOwner] = EOS;
			strins(bInfo[pInfo[playerid][pHouseID]][bOwner], pInfo[playerid][pName], 0);

			SendClientMessage(playerid, -1, "Вы успешно приобрели бизнес.");
			GivePlayerMoney(playerid, -bInfo[pInfo[playerid][pHouseID]][bPrice]);
		}

		case DIALOG_BUSINESS_INFO:
		{
			if(!response) return ShowPlayerDialog(playerid, DIALOG_BUSINESS_ENTER, DIALOG_STYLE_LIST, bInfo[pInfo[playerid][pHouseID]][bName], "Войти\nПосмотреть информацию о бизнесе\nПриобрести", "Выбрать", "Выход");
		}

		case DIALOG_REGISTER:
		{
			if(!response) return Kick(playerid);

			if(!strlen(inputtext)) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Введите пароль", "пароль быстро", "Продолжить", "Выход");
			if(strlen(inputtext) < 4 || strlen(inputtext) > 28) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Введите пароль", "пароль быстро", "Продолжить", "Выход");

			for(new i; i < strlen(inputtext); i++)
			{
				switch(inputtext[i])
				{
					case 'A'..'Z', 'a'..'z', '0'..'9': continue;
					default: return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Введите пароль", "пароль быстро", "Продолжить", "Выход");
				}
			}

			strins(pInfo[playerid][pPassword], inputtext, 0);

			new query[62 + MAX_PLAYER_NAME - 2 - 2 + 30];
			mysql_format(ConnectID, query, sizeof(query), "INSERT INTO users (Login, Password) VALUES ('%s', '%s')", pInfo[playerid][pName], pInfo[playerid][pPassword]);
			mysql_tquery(ConnectID, query, "OnPlayerRegister");

			SendClientMessage(playerid, -1, "Вы успешно прошли регистрацию.");
		}

		case DIALOG_LOGIN:
		{
			if(!response) return Kick(playerid);

			if(!strlen(inputtext)) return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Введите пароль", "пароль быстро для авторизации", "Продолжить", "Выход");
			if(strlen(inputtext) < 4 || strlen(inputtext) > 28) return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Введите пароль", "пароль быстро для авторизации", "Продолжить", "Выход");
			
			for(new i; i < strlen(inputtext); i++)
			{
				switch(inputtext[i])
				{
					case 'A'..'Z', 'a'..'z', '0'..'9': continue;
					default: return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Введите пароль", "пароль быстро для авторизации", "Продолжить", "Выход");
				}
			}

			if(!strcmp(pInfo[playerid][pPassword], inputtext))
			{
				new query_string[49 + MAX_PLAYER_NAME];
				format(query_string, sizeof(query_string), "SELECT * FROM users WHERE Login = '%s'", pInfo[playerid][pName]);
				mysql_tquery(ConnectID, query_string, "UploadPlayerAccount", "i", playerid);
			}
			else 
			{
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Введите пароль", "пароль быстро для авторизации", "Продолжить", "Выход");
			}

		}

		case DIALOG_SPAWNS:
		{
			if(listitem == 0)
			{
				pInfo[playerid][pSpawnPlace] = SPAWN_LS;
				SendClientMessage(playerid, -1, "Вы сменили место спавна на Лос Сантос.");
			}

			if(listitem == 1)
			{
				pInfo[playerid][pSpawnPlace] = SPAWN_SF;
				SendClientMessage(playerid, -1, "Вы сменили место спавна на Сан Фиерро.");
			}

			if(listitem == 2)
			{
				pInfo[playerid][pSpawnPlace] = SPAWN_LV;
				SendClientMessage(playerid, -1, "Вы сменили место спавна на Лас Вентурас.");
			}

			if(listitem == 3)
			{
				pInfo[playerid][pSpawnPlace] = SPAWN_ALL;
				SendClientMessage(playerid, -1, "Теперь вы будете появляться везде.");
			}
		}
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new str_text[128];
	format(str_text, sizeof(str_text), "%s(%d): {FFFFFF}%s", pInfo[playerid][pName], playerid, text);
	SendClientMessageToAll(GetPlayerColor(playerid), str_text);
	return 0;
}