#define NOMINMAX
#include "fragManager.hpp"
#include <random>

float vectDir(vector3 in) {
    auto x = atan2(in.x, in.y);
    return fmod(fmod(x, 360.f) + 360.f, 360.f);
}

vector3 vecToPolar(vector3 in) {
    auto mag = in.magnitude();
    auto elev = mag > 0 ? asin(in.z / mag) : 0;
    auto dir = vectDir(in);
    return { mag, dir, elev };
}

vector3 polarToVect(vector3 in) {
    auto magCosElev = in.x * cos(in.z);
    return { magCosElev * sin(in.y), magCosElev * cos(in.y),in.x * sin(in.z) };
}




spallObj::spallObj(std::shared_ptr<ammoInfoCache::ammoInfo> ammo, r_string ammoClass, object projectile, object _shooter, bool _shouldSpall) {
    lastPosition = sqf::get_pos_asl(projectile);
    lastVelocity = sqf::velocity(projectile);
    firedFrame = sqf::diag_frameno();
    shouldSpall = _shouldSpall;
    ammoInfo = ammo;
    shooter = _shooter;
    ammoClassname = ammoClass;

}

void spallObj::doSpall(std::vector<client::eventhandler_hit_part_type> hits, size_t EHIndex) {
    spallHPs[EHIndex] = client::EHIdentifierHandle(); //removeEventHandler
    if (!(ammoInfo->caliber >= 2.5f ||
        (ammoInfo->explosive > 0
            &&
            ammoInfo->indirectHitRange >= 1))) return;
    //doSpall
    for (auto& hit : hits) {
        float vm = 1.f;
        auto oldVelocity = lastVelocity.magnitude();
        auto curVelocity = sqf::velocity(projectile).magnitude();

        if (sqf::alive(projectile)) {
            auto diff = lastVelocity - sqf::velocity(projectile);
            auto polar = vecToPolar(diff);
            if (abs(polar.x) > 45 || abs(polar.z) > 45) {
                if (ammoInfo->caliber < 2.5f) return;
                vm -= curVelocity / oldVelocity;
            }
        }
        auto unitDir = lastVelocity.normalize();
        auto pos = hit.position;
        vector3 spallPos;
        for (size_t i = 0; i < 100; i++) {
            auto pos1 = pos + unitDir*(0.01f * i);
            auto pos2 = pos + unitDir*(0.01f * (i + 1));
            if (!sqf::line_intersects(pos1, pos2)) {
                spallPos = pos2;
                break;
            }
        }
        if (spallPos.zero_distance()) return;
        auto spallPolar = vecToPolar(lastVelocity);

        if (ammoInfo->explosive > 0) {
            auto c = ammoInfo->charge;
            if (c == 0) c = 1;
            auto m = ammoInfo->metal;
            if (m == 0) c = 1;
            auto k = ammoInfo->gurney_k;
            if (k == 0) c = 1;
            auto gC = ammoInfo->gurney_c;
            if (gC == 0) c = 1;
            auto fragPower = pow(((m / c) + k), -(1 / 2)) * gC;
            spallPolar.x = fragPower * 0.66f;
        }
        static std::array<std::string_view, 12> fragTypes{
            "ace_frag_spall_small"sv,
            "ace_frag_spall_small"sv,
            "ace_frag_spall_small"sv,
            "ace_frag_spall_small"sv,
            "ace_frag_spall_medium"sv,
            "ace_frag_spall_medium"sv,
            "ace_frag_spall_medium"sv,
            "ace_frag_spall_medium"sv,
            "ace_frag_spall_large"sv,
            "ace_frag_spall_large"sv,
            "ace_frag_spall_huge"sv,
            "ace_frag_spall_huge"sv
        };

        static std::default_random_engine rng(std::random_device{}());
        std::uniform_real_distribution<float> dist1(15.f, 15.f + 25.f);
        std::uniform_int_distribution<int> dist2(5, 5 + 10);

        auto spread = dist1(rng);
        auto spallCount = dist2(rng);
        std::uniform_real_distribution<float> dist3(0, spread * 2);
        std::uniform_int_distribution<size_t> fragTypesDist(0, fragTypes.size() - 1);
        for (int i = 0; i < spallCount; i++) {
            auto elev = spallPolar.z - spread + dist3(rng);
            auto dir = spallPolar.y - spread + dist3(rng);

            if (abs(elev) > 90)
                dir += 180;
            dir = fmod(dir, 360.f);
            auto vel = spallPolar.x * 0.33f * vm;
            std::uniform_real_distribution<float> dist6(0, vel * 0.5f);
            vel = vel - vel*0.25f + dist6(rng);
            auto spallFragVect = polarToVect({ vel, dir, elev });
            auto fragType = fragTypesDist(rng);
            auto fragment = sqf::create_vehicle_local(fragTypes[fragType], { 0,0,10000 });
            sqf::set_pos_asl(fragment, spallPos);
            sqf::set_velocity(fragment, spallFragVect);
        }

        std::uniform_real_distribution<float> dist4(5, 10);
        std::uniform_int_distribution<int> dist5(3, 5 + 3);

        spread = dist1(rng);
        spallCount = dist2(rng);
        for (int i = 0; i < spallCount; i++) {
            auto elev = spallPolar.z - spread + dist3(rng);
            auto dir = spallPolar.y - spread + dist3(rng);

            if (abs(elev) > 90)
                dir += 180;
            dir = fmod(dir, 360.f);
            auto vel = spallPolar.x * 0.33f * vm;
            std::uniform_real_distribution<float> dist6(0, vel * 0.5f);
            vel = vel - vel*0.25f + dist6(rng);
            auto spallFragVect = polarToVect({ vel, dir, elev });
            auto fragType = fragTypesDist(rng);
            auto fragment = sqf::create_vehicle_local(fragTypes[fragType], { 0,0,10000 });
            sqf::set_pos_asl(fragment, spallPos);
            sqf::set_velocity(fragment, spallFragVect);
        }

    }


}




void spallObj::spallTrack(float multiplier) {

    auto delta = (1 / sqf::diag_fps()) * multiplier;
    auto curPos = sqf::get_pos_asl(projectile);
    auto velocity = sqf::velocity(projectile);

    auto velocityStep = velocity*delta;
    auto forwardPos = curPos + velocityStep;
    auto intersectsWith = sqf::line_intersects_with(curPos, forwardPos);
    if (intersectsWith.empty()) return;

    for (auto& intersect : intersectsWith) {
        if (std::find(foundObjects.begin(), foundObjects.end(), intersect) != foundObjects.end()) continue;
        size_t index = spallHPs.size();
        auto hpID = client::addEventHandler<client::eventhandlers_object::HitPart>(intersect, [this, index](std::vector<client::eventhandler_hit_part_type> hits) {
            auto& first = hits.front();
            if (!first.direct || first.bullet != projectile) return;
            doSpall(hits, index);
        });
        spallHPs.push_back(hpID);
        foundObjects.push_back(intersect);
    }


}

bool spallObj::pfhRound(fragManager& manager) {
    if (std::find(manager.blacklist.begin(), manager.blacklist.end(), projectile) != manager.blacklist.end()) return false;

    if (!sqf::alive(projectile)) {
        if (sqf::diag_frameno() - firedFrame > 1 && ammoInfo->skip == 0
            &&
            ammoInfo->force == 1 ||
            (ammoInfo->explosive > 0.5 && ammoInfo->indirectRange >= 4.5 && ammoInfo->fragPower >= 35)
            ) { //skip if deleted within a single frame
            if (lastPosition.z < 0 && (ammoInfo->simulation == "shotbullet"sv || ammoInfo->simulation == "shotshell"sv)) return false; //#TODO check if return val is correct.
            bool isArmed = true;
            if (!shooter.is_nil()) {
                isArmed = (sqf::get_pos_asl(shooter).distance(lastPosition) > ammoInfo->fuseDistance);
            }
            if (!isArmed) return false;
            //send event to server
            auto CBA_fnc_serverEvent = sqf::get_variable(sqf::mission_namespace(), "CBA_fnc_serverEvent");
            sqf::call(CBA_fnc_serverEvent, { "ace_frag_frag_eh", {lastPosition, lastVelocity, ammoClassname} });
        }
        if (shouldSpall) {
            manager.spallIsTrackingCount--;
            spallHPs.clear();
        }
            
        return false;
    }
    lastPosition = sqf::get_pos_asl(projectile);
    lastVelocity = sqf::velocity(projectile);
    if (shouldSpall) {
        float maxTrackPerFrame = sqf::get_variable(sqf::mission_namespace(), "ace_frag_maxTrackPerFrame");
        auto scale = std::max(0.f, manager.objects.size() / maxTrackPerFrame);
        spallTrack(scale);
    }
    return true;
}


fragManager::fragManager() {
    lastTrack = std::chrono::system_clock::now();
}
fragManager::~fragManager() {}



void fragManager::addPfhRound(object shooter, r_string ammoClasssname, object projectile) {
    bool enabled = sqf::get_variable(sqf::mission_namespace(), "ace_frag_enabled");
    if (!enabled) return;
    if (!sqf::alive(projectile)) return; //wtf?

    auto found = std::find(blacklist.begin(), blacklist.end(), projectile);
    if (found != blacklist.end()) {
        blacklist.erase(found);
        return;
    }



    float maxTrack = sqf::get_variable(sqf::mission_namespace(), "ace_frag_maxTrack");
    if (objects.size() > maxTrack) return;

    bool doSpall = false;
    bool SpallEnabled = sqf::get_variable(sqf::mission_namespace(), "ace_frag_SpallEnabled");
    if (SpallEnabled) {
      if (spallIsTrackingCount <= 0) {
          objects.clear();
      }
      if (spallIsTrackingCount > 5) {
         //TRACE_1("At Spall Limit",GVAR(spallIsTrackingCount));
      } else {
          doSpall = true;
          ++spallIsTrackingCount;
      }
    }

    auto obj = std::make_shared<spallObj>(ammoCache.get(ammoClasssname), ammoClasssname, projectile, shooter, doSpall);
    objects.push_back(obj);
}
void fragManager::masterPFH() {
    if (objects.empty()) return;
    std::vector<std::shared_ptr<spallObj>> to_remove;

    for (auto& object : objects) {
        bool ret = object->pfhRound(*this);
        if (!ret) to_remove.push_back(object);
    }
    for (auto& toDel : to_remove) {
        auto found = std::find(objects.begin(), objects.end(), toDel);
        if (found != objects.end()) objects.erase(found);
    }
}

void fragManager::fired(const game_value& args) {
    //args == ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", _vehicle, _gunner, _turret]
    r_string _ammo = args[4];
    auto ammoInfo = ammoCache.get(_ammo);

    if (!ammoInfo->shouldAdd) return;
    object _unit = args[0];
    object _gunner = args[8];
    bool _localShooter = _gunner.is_nil() ? sqf::local(_unit) : sqf::local(_gunner);
    if (!_localShooter) return;
    auto secondsSinceLastShot = std::chrono::duration<float>(std::chrono::system_clock::now() - lastTrack).count();
    // Skip if less than 0.5 second from last shot
    if (secondsSinceLastShot < 0.5f) return;
    lastTrack = std::chrono::system_clock::now();

    addPfhRound(_unit, _ammo, args[6]);
}

template<typename Iter, typename RandomGenerator>
Iter select_random(Iter start, Iter end, RandomGenerator& g) {
    std::uniform_int_distribution<> dis(0, std::distance(start, end) - 1);
    std::advance(start, dis(g));
    return start;
}


void fragManager::frago(const game_value& args) {
    static std::default_random_engine rng(std::random_device{}());

#define FRAG_VEC_VAR 0.004f
#define MAX_FRAG_COUNT 50

    vector3 lastPos = args[0];
    vector3 lastVelocity = args[1];
    r_string ammoClassname = args[0];

    auto secondsSinceLastFrag = std::chrono::duration<float>(std::chrono::system_clock::now() - lastFragTime).count();
    // Skip if less than 0.5 second from last shot

    auto _maxFrags = round(MAX_FRAG_COUNT * sqf::linear_conversion(0.1f, 1.5f,
        secondsSinceLastFrag, 0.1f, 1.f, true));
    lastFragTime = std::chrono::system_clock::now();
    auto ammoInfo = ammoCache.get(ammoClassname);

    static std::vector<r_string> fragTypesDefault{
        "ace_frag_tiny"sv,
        "ace_frag_tiny"sv,
        "ace_frag_tiny"sv,
        "ace_frag_tiny_HD"sv,
        "ace_frag_tiny_HD"sv,
        "ace_frag_tiny_HD"sv,
        "ace_frag_small"sv,
        "ace_frag_small"sv,
        "ace_frag_small"sv,
        "ace_frag_small"sv,
        "ace_frag_small_HD"sv,
        "ace_frag_small_HD"sv,
        "ace_frag_small_HD"sv,
        "ace_frag_small_HD"sv,
        "ace_frag_medium_HD"sv,
        "ace_frag_medium_HD"sv,
        "ace_frag_medium_HD"sv,
        "ace_frag_medium_HD"sv,
        "ace_frag_medium_HD"sv
    };



    std::vector<r_string> fragTypes = ammoInfo->fragTypes;

    if (fragTypes.empty())
        fragTypes = fragTypesDefault;
    auto fragRange = 20 * ammoInfo->indirectHitRange * 4;

    // Gunery equation is for a non-fragmenting metal, imperical value of 80% represents fragmentation
    auto _fragPower = 0.8f * pow((ammoInfo->metal / ammoInfo->charge) + ammoInfo->gurney_k, -(1 / 2)) * ammoInfo->gurney_c;
    auto atlPos = sqf::asl_to_agl(lastPos);

    auto fragPowerRandom = _fragPower*0.5f;
    std::uniform_real_distribution<float> fragPowRand(0, fragPowerRandom);
    if (atlPos.z < 0.5) lastPos += {0, 0, 0.5};
    static std::vector<r_string> entityTypes{ "Car"sv, "Motorcycle"sv, "Tank"sv, "StaticWeapon"sv, "CAManBase"sv, "Air"sv, "Ship"sv };
    std::vector<object> objects2 = sqf::near_entities(atlPos, entityTypes, fragRange);
    std::vector<object> objects = objects2;
    for (auto& object : objects2) {
        for (auto& it : sqf::crew(object))
            if (std::find(objects.begin(), objects.end(), object) == objects.end())
                objects.push_back(object);
    }
    if (objects.empty()) return;


    uint32_t fragCount = 0;

    bool reflectionsEnabled = sqf::get_variable(sqf::ui_namespace(), "ace_frag_reflectionsEnabled");
    if (reflectionsEnabled) doReflections(lastPos, ammoClassname);

    std::map<float, float> fragArcs;
    fragArcs[360.f] = 0.f;

    for (auto& object : objects) {

        if (!sqf::alive(object)) continue;
        auto bounds = sqf::bounding_box(object);

        auto _cubic = ((abs(bounds.min.x)) + (bounds.max.x)) * ((abs(bounds.min.y)) + (bounds.max.x)) * ((abs(bounds.min.z)) + (bounds.max.z));
        if (_cubic <= 1) continue;
        auto targetVel = sqf::velocity(object);
        auto targetPos = sqf::get_pos_asl(object);
        auto distance = targetPos.distance(lastPos);
        auto _add = ((bounds.max.z) / 2) + ((std::max((distance - (_fragPower / 8)), 0.f) / _fragPower) * 10);

        targetPos += {
            targetVel.x * (distance / _fragPower),
                targetVel.y * (distance / _fragPower),
                _add};

        auto baseVec = (lastPos - targetPos).normalize();

        auto dir = floor(vectDir(baseVec));
        auto currentCount = fragArcs[dir];
        if (currentCount < 10) {
            std::uniform_real_distribution<float> dist1(0, sqrt(ammoInfo->metal / 1000));
            auto count = ceil(dist1(rng));
            auto vecVar = FRAG_VEC_VAR;
            if (!sqf::is_kind_of(object, "Man"sv)) {
                vecVar += sqrt(_cubic) / 2000;
                if (sqf::crew(object).empty() && count > 0)
                    count = std::max(0.f, count / 2);
            }
            std::uniform_real_distribution<float> vecVarRand(0, vecVar);


            for (float i = 0.f; i < count; i += 1.f) {
                auto vec = baseVec - vector3{
                    vecVar / 2.f + vecVarRand(rng),
                    vecVar / 2.f + vecVarRand(rng),
                    vecVar / 2.f + vecVarRand(rng)
                };
                auto fp = _fragPower - fragPowRand(rng);
                auto vel = vec*fp;
                auto fragType = *select_random(fragTypes.begin(), fragTypes.end(), rng);
                auto fragObj = sqf::create_vehicle_local(fragType, { 0,0,10000 });
                sqf::set_pos_asl(fragObj, lastPos);
                sqf::set_vector_dir(fragObj, vec);
                sqf::set_velocity(fragObj, vel);
                fragCount++;
                currentCount += 1.f;
            }
            fragArcs[dir] = currentCount;
        }
        if (fragCount > _maxFrags) return;
    }
    if (fragCount > _maxFrags) return;
    auto randomCount = (_maxFrags - fragCount) * 0.35f;
    auto sectorSize = 360.f / std::max(randomCount, 1.f);

    std::uniform_real_distribution<float> sectorSizeRand(0, sectorSize);
    std::uniform_real_distribution<float> rand45(0, 45);


    //if doRandom. Is never set to false so we just do it.
    for (float i = 0; i < randomCount; i += 1.f) {
        auto sectorOffset = 360.f * (i - 1) / std::max(randomCount, 1.f);
        auto randomDir = sectorSizeRand(rng);

        vector3 vec = {
            cos(sectorOffset + randomDir),
            sin(sectorOffset + randomDir),
            sin(30.f - rand45(rng))
        };
        auto fp = _fragPower - fragPowRand(rng);
        auto vel = vec * fp;

        auto fragType = *select_random(fragTypes.begin(), fragTypes.end(), rng);
        auto fragObj = sqf::create_vehicle_local(fragType, { 0,0,10000 });
        sqf::set_pos_asl(fragObj, lastPos);
        sqf::set_vector_dir(fragObj, vec);
        sqf::set_velocity(fragObj, vel);

        ++fragCount;
    }



}



struct explosionStruct {
    r_string refExp;
    vector3 bpos;
    float hit;
    float distance;
    float indirectHitRange;
    float depth;
};

void fragManager::doReflections(vector3 pos, r_string ammoClassname) {
    auto ammoInfo = ammoCache.get(ammoClassname);
    auto handle = std::make_shared<client::EHIdentifierHandle>();
    *handle = client::addMissionEventHandler<client::eventhandlers_mission::EachFrame>([handle, ammoInfo, pos]() {
        auto depth = 1.f;//never get's any other value than it's default

        static int zIndex = -4;
        static std::vector<vector3> nlos;

        //[_pos, [_indirectHitRange, _indirectHit], [], [], -4, _depth, 0];


        auto split = 15.f;
        auto radi = 360.f / split * depth;

        uint32_t distanceCount = std::min(100u, (uint32_t) floor(ammoInfo->indirectHitRange));

        if (zIndex < 5) {
            auto lastPos = pos;

            auto zAng = zIndex * 20 + 2;
            if (zAng > 80) {
                radi = 1; zAng = 90;
            }
            for (float i = 0.f; i < radi; i += 1) {
                bool test = true;

                auto vec = polarToVect({
                1,
                    fmod(i*split,360.f),
                    (float)zAng });
                for (uint32_t x = 0; x < distanceCount; x++) {
                    auto testPos = pos + vec * (float)x;
                    auto res = sqf::line_intersects_with(pos, testPos);
                    if (res.size() > 0) {
                        test = false;
                        nlos.push_back(lastPos);
                    }
                    lastPos = testPos;
                }
            }
            ++zIndex;


        } else {
            depth += 1.f;

            std::vector<std::pair<vector3, std::vector<vector3>>> buckets;
            std::vector<uint32_t> excludes;
            vector3 bucketPos;
            std::vector<vector3>* bucketList;
            uint32_t c = 0;
            while (nlos.size() != excludes.size() && c < nlos.size()) {
                uint32_t _forEachIndex = 0;
                for (auto& it : nlos) {
                    if (std::find(excludes.begin(), excludes.end(), _forEachIndex) == excludes.end()) {
                        buckets.push_back({ it,{it} });
                        excludes.push_back(_forEachIndex);
                        bucketPos = it;
                        bucketList = &buckets.back().second;
                        break;
                    }
                    ++_forEachIndex;
                }

                _forEachIndex = 0;
                for (auto& it : nlos) {
                    if (std::find(excludes.begin(), excludes.end(), _forEachIndex) == excludes.end()) {
                        if (it.distance_squared(bucketPos) <= 30) {
                            excludes.push_back(_forEachIndex);
                            bucketList->push_back(it);
                        }
                    }
                    ++_forEachIndex;
                }
                ++c;
            }

            std::vector<explosionStruct> explosions;

            for (auto& bucket : buckets) {
                auto& blist = bucket.second;
                vector3 avg;

                for (auto& it : blist) {
                    avg += it;
                }
                auto bpos = avg * (1.f / blist.size());
                auto distance = pos.distance(bpos);
                auto hitFactor = 1 - std::max(0.f, std::min(1.f, distance / (ammoInfo->indirectHitRange * 4)));
                float hit = std::min(500.f, floor(ammoInfo->indirectHit*hitFactor / 4));
                hit -= fmod(hit, 10.f);
                auto range = std::min(100.f, floor(ammoInfo->indirectHitRange - (distance / 4)));
                range -= fmod(range, 2.f);

                if (hit >= 10 && range > 0) {
                    auto refExp = sqf::format({ "ace_explosion_reflection_%1_%2", range, hit });
                    explosions.emplace_back(explosionStruct{
                        refExp,
                        bpos,
                        hit,
                        distance,
                        ammoInfo->indirectHitRange / 4,
                        depth
                });
                }
            }



            auto handle2 = std::make_shared<client::EHIdentifierHandle>();
            *handle2 = client::addMissionEventHandler<client::eventhandlers_mission::EachFrame>([handle2, explosions]() {
                //doExplosions
                static uint32_t index = 0;

                for (uint32_t i = 0; i < std::min(explosions.size(), index + 2); ++i) {
                    auto& exp = explosions[i];
                    sqf::create_vehicle(exp.refExp, sqf::asl_to_atl(exp.bpos));
                }
                index += 2;
                if (index >= explosions.size()) {
                    *handle2 = client::EHIdentifierHandle(); //remove PFH
                }

            });
            *handle = client::EHIdentifierHandle(); //remove PFH
        }






    });



}
