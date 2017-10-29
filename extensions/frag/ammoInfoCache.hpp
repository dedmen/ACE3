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
            float _indirectHitRange,
            float _charge,
            float _metal,
            float _gurney_k,
            float _gurney_c) :
            skip(_skip),
            explosive(_explosive),
            indirectRange(_indirectRange),
            force(_force),
            fragPower(_fragPower),
            caliber(_caliber),
            indirectHitRange(_indirectHitRange),
            charge(_charge),
            metal(_metal),
            gurney_k(_gurney_k),
            gurney_c(_gurney_c)
        {}

        bool shouldAdd;
        float skip;
        float explosive;
        float indirectRange;
        float force;
        float fragPower;
        float caliber;
        float indirectHitRange;
        float charge;
        float metal;
        float gurney_k;
        float gurney_c;
    };

    ammoInfoCache();
    ~ammoInfoCache();
    std::shared_ptr<ammoInfo> get(r_string className);

private:
    std::unordered_map<r_string, std::shared_ptr<ammoInfo>> cache;
};
