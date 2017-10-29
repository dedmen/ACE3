#include "ammoInfoCache.hpp"

using namespace intercept;

ammoInfoCache::ammoInfoCache() {}
ammoInfoCache::~ammoInfoCache() {}
std::shared_ptr<ammoInfoCache::ammoInfo> ammoInfoCache::get(r_string className) {
    auto found = cache.find(className);
    if (found != cache.end()) {
        return found->second;
    }

    auto cfg = sqf::config_entry() >> "CfgAmmo" >> className;
    auto info = std::make_shared<ammoInfoCache::ammoInfo>(
        sqf::get_number(cfg >> "ace_frag_skip"),
        sqf::get_number(cfg >> "explosive"),
        sqf::get_number(cfg >> "indirectHitRange"),
        sqf::get_number(cfg >> "ace_frag_force"),
        sqf::get_number(cfg >> "indirecthit")*
        sqrt(sqf::get_number(cfg >> "indirectHitRange")),
        sqf::get_number(cfg >> "caliber"),
        sqf::get_number(cfg >> "indirectHitRange"),
        sqf::get_number(cfg >> "ace_frag_CHARGE"),
        sqf::get_number(cfg >> "ace_frag_METAL"),
        sqf::get_number(cfg >> "ace_frag_GURNEY_K"),
        sqf::get_number(cfg >> "ace_frag_GURNEY_C")
        );
    info->shouldAdd = info->skip == 0 &&
        (info->force == 1 ||
            (info->explosive > 0.5f && info->indirectRange >= 4.5f && info->fragPower >= 35)
            );
    cache[className] = info;
    return info;
}
