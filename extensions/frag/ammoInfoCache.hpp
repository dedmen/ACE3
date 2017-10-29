#pragma once
#include "intercept.hpp"
#include <unordered_map>
#include <memory>

class ammoInfoCache {
public:
    struct ammoInfo {
        ammoInfo (float _skip,
            float _explosive,
            float _indirectRange,
            float _force,
            float _fragPower,
            float _caliber,
            float _indirectHit,
            float _indirectHitRange,
            float _charge,
            float _metal,
            float _gurney_k,
            float _gurney_c,
            r_string _simulation,
            float _fuseDistance,
            std::vector<r_string> _fragTypes) :
            skip(_skip),
            explosive(_explosive),
            indirectRange(_indirectRange),
            force(_force),
            fragPower(_fragPower),
            caliber(_caliber),
            indirectHit(_indirectHit),
            indirectHitRange(_indirectHitRange),
            charge(_charge == 0 ? 1.f : _charge),
            metal(_metal == 0 ? 2.f : _metal),
            gurney_k(_gurney_k == 0 ? 0.5f : _gurney_k),
            gurney_c(_gurney_c == 0 ? 2440.f : _gurney_c),
            simulation(_simulation),
            fuseDistance(_fuseDistance),
            fragTypes(_fragTypes)
        {}

        bool shouldAdd;
        float skip;
        float explosive;
        float indirectRange;
        float force;
        float fragPower;
        float caliber;
        float indirectHit;
        float indirectHitRange;
        float charge;
        float metal;
        float gurney_k;
        float gurney_c;
        r_string simulation;
        float fuseDistance;
        std::vector<r_string> fragTypes;
    };

    ammoInfoCache();
    ~ammoInfoCache();
    std::shared_ptr<ammoInfo> get(r_string className);

private:
    std::unordered_map<r_string, std::shared_ptr<ammoInfo>> cache;
};
