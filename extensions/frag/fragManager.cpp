#include "fragManager.hpp"
#include <random>

float vectDir(vector3 in) {
    auto x = atan2(in.x, in.y);
    return fmod(fmod(x,360) + 360,360);
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




spallObj::spallObj(std::shared_ptr<ammoInfoCache::ammoInfo> ammo, object projectile, object _shooter) {
    //#TODO init variables
    initialVelocity = sqf::velocity(projectile);
    ammoInfo = ammo;
    shooter = _shooter;

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
         auto oldVelocity = initialVelocity.magnitude();
         auto curVelocity = sqf::velocity(projectile).magnitude();

         if (sqf::alive(projectile)) {
             auto diff = initialVelocity - sqf::velocity(projectile);
             auto polar = vecToPolar(diff);
             if (abs(polar.x) > 45 || abs(polar.z) > 45) {
                 if (ammoInfo->caliber < 2.5f) return;
                 vm -= curVelocity / oldVelocity;
             }
         }
         auto unitDir = initialVelocity.normalize();
         auto pos = hit.position;
         vector3 spallPos;
         for (size_t i = 0; i < 100; i++) {
             auto pos1 = pos + unitDir*(0.01f * i);
             auto pos2 = pos + unitDir*(0.01f * (i+1));
             if (!sqf::line_intersects(pos1,pos2)) {
                 spallPos = pos2;
                 break;
             }
         }
         if (spallPos.zero_distance()) return;
         auto spallPolar = vecToPolar(initialVelocity);

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
             spallPolar.x = fragPower * 0.66;
         }
         static std::array<std::string_view,12> fragTypes{
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
         std::uniform_int_distribution<float> dist1(15, 15+25);
         std::uniform_int_distribution<int> dist2(5, 5+10);

         auto spread = dist1(rng);
         auto spallCount = dist2(rng);
         std::uniform_int_distribution<float> dist3(0, spread*2);
         std::uniform_int_distribution<size_t> fragTypesDist(0, fragTypes.size()-1);
          for (int i = 0; i < spallCount; i++) {
              auto elev = spallPolar.z - spread + dist3(rng);
              auto dir = spallPolar.y - spread + dist3(rng);

              if (abs(elev) > 90)
                  dir += 180;
              dir = fmod(dir, 360.f);
              auto vel = spallPolar.x * 0.33 * vm;
              std::uniform_int_distribution<int32_t> dist3(0, vel * 0.5);
              vel = vel - vel*0.25 + dist3(rng);
              auto spallFragVect = polarToVect({ vel, dir, elev });
              auto fragType = fragTypesDist(rng);
              auto fragment = sqf::create_vehicle_local(fragTypes[fragType], { 0,0,10000 });
              sqf::set_pos_asl(fragment,spallPos);
              sqf::set_velocity(fragment, spallFragVect);
          }

          std::uniform_int_distribution<float> dist4(5, 10);
          std::uniform_int_distribution<int> dist5(3, 5+3);

          spread = dist1(rng);
          spallCount = dist2(rng);
          for (int i = 0; i < spallCount; i++) {
              auto elev = spallPolar.z - spread + dist3(rng);
              auto dir = spallPolar.y - spread + dist3(rng);

              if (abs(elev) > 90)
                  dir += 180;
              dir = fmod(dir, 360.f);
              auto vel = spallPolar.x * 0.33 * vm;
              std::uniform_int_distribution<int32_t> dist3(0, vel * 0.5);
              vel = vel - vel*0.25 + dist3(rng);
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
        //#TODO foundObjects check
        size_t index = spallHPs.size();
        auto hpID = client::addEventHandler<client::eventhandlers_object::HitPart>(intersect, [this, index](std::vector<client::eventhandler_hit_part_type> hits) {
            auto& first = hits.front();
            if (!first.direct || first.bullet != projectile) return;
            doSpall(hits, index);
        });
        spallHPs.push_back(hpID);
    }


}

bool spallObj::pfhRound() {
    






}


fragManager::fragManager() {
    lastTrack = std::chrono::system_clock::now();
}
fragManager::~fragManager() {}



void fragManager::addPfhRound(object shooter, r_string ammoClasssname, object projectile) {
    bool enabled = sqf::get_variable(sqf::mission_namespace(), "ace_frag_enabled");
    if (!enabled) return;
    if (!sqf::alive(projectile)) return; //wtf?


    //#TODO blacklist check

     float maxTrack = sqf::get_variable(sqf::mission_namespace(), "ace_frag_maxTrack");
     //#TODO objects array check
     bool doSpall = false;
     bool SpallEnabled = sqf::get_variable(sqf::mission_namespace(), "ace_frag_SpallEnabled");
     if (SpallEnabled) {
         




     }

     auto obj = std::make_shared<spallObj>(ammoCache.get(ammoClasssname), projectile, shooter);
     objects.push_back(obj);
}
void fragManager::masterPFH() {
    if (objects.empty()) return;
    std::vector<std::shared_ptr<spallObj>> to_remove;

    for (auto& object : objects) {
        bool ret = object.pfhRound();
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
