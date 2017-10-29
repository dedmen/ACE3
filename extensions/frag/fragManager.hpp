#pragma once
#include "intercept.hpp"
#include <vector>
#include <chrono>
#include "ammoInfoCache.hpp"
#include <memory>
using namespace intercept;
using namespace intercept::types;

class spallObj {
public:
    spallObj(std::shared_ptr<ammoInfoCache::ammoInfo> ammo, object projectile, object shooter
        /*, bool doSpall*/
    );
    void doSpall(std::vector<client::eventhandler_hit_part_type> hits, size_t EHindex);
    void spallTrack(float multiplier);
    bool pfhRound();
    object projectile;
    object shooter;
    vector3 initialVelocity;
    //bool doSpall;
    std::shared_ptr<ammoInfoCache::ammoInfo> ammoInfo;
    std::vector<client::EHIdentifierHandle> spallHPs;
};


class fragManager {
public:
    fragManager();
    ~fragManager();

    void addPfhRound(object shooter, r_string ammoClasssname, object projectile);
    void masterPFH();
    void fired(const game_value& args);
    ammoInfoCache ammoCache;
    //lastShot
    std::chrono::system_clock::time_point lastTrack;
    std::vector<std::shared_ptr<spallObj>> objects;
};

