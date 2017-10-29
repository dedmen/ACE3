#pragma once
#include "intercept.hpp"
#include <vector>
#include <chrono>
#include "ammoInfoCache.hpp"
#include <memory>
class fragManager;
using namespace intercept;
using namespace intercept::types;

class spallObj {
public:
    spallObj(std::shared_ptr<ammoInfoCache::ammoInfo> ammo, r_string ammoClass, object projectile, object shooter
        , bool shouldSpall
    );
    void doSpall(std::vector<client::eventhandler_hit_part_type> hits, size_t EHindex);
    void spallTrack(float multiplier);
    bool pfhRound(fragManager& manager);

    game_value_static projectile;
    vector3 lastPosition;
    vector3 lastVelocity;
    r_string ammoClassname;
    float firedFrame;
    game_value_static shooter;
   
    bool shouldSpall;
    std::shared_ptr<ammoInfoCache::ammoInfo> ammoInfo;
    std::vector<client::EHIdentifierHandle> spallHPs;
    std::vector<game_value_static> foundObjects;
};


class fragManager {
public:
    fragManager();
    ~fragManager();

    void addPfhRound(object shooter, r_string ammoClasssname, object projectile);
    void masterPFH();
    void fired(const game_value& args);
    void doReflections(vector3 lastPos, r_string ammoClassname);
    void frago(const game_value& args);
    ammoInfoCache ammoCache;
    //lastShot
    std::chrono::system_clock::time_point lastTrack;
    std::chrono::system_clock::time_point lastFragTime;
    std::vector<std::shared_ptr<spallObj>> objects;
    std::vector<object> blacklist;
    int32_t spallIsTrackingCount = 0;
};

