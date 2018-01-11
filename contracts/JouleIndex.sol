pragma solidity ^0.4.18;

import "./KeysUtils.sol";

contract JouleIndex {
    using KeysUtils for bytes32;

    // year -> month -> day -> hour
    mapping (bytes32 => bytes32) index;
    bytes32 head;

    function insert(bytes32 _key) public {
        uint timestamp = _key.getTimestamp();
        bytes32 year = toKey(timestamp, 1 years);
        bytes32 headLow;
        bytes32 headHigh;
        (headLow, headHigh) = fromValue(head);
        if (year < headLow || headLow == 0 || year > headHigh) {
            if (year < headLow || headLow == 0) {
                headLow = year;
            }
            if (year > headHigh) {
                headHigh = year;
            }
            head = toValue(headLow, headHigh);
        }

        bytes32 week = toKey(timestamp, 1 weeks);
        bytes32 low;
        bytes32 high;
        (low, high) = fromValue(index[year]);
        if (week < low || week > high) {
            if (week < low || low == 0) {
                low = week;
            }
            if (week > high) {
                high = week;
            }
            index[year] = toValue(low, high);
        }

        (low, high) = fromValue(index[week]);
        bytes32 hour = toKey(timestamp, 1 hours);
        if (hour < low || hour > high) {
            if (hour < low || low == 0) {
                low = hour;
            }
            if (hour > high) {
                high = hour;
            }
            index[week] = toValue(low, high);
        }

        (low, high) = fromValue(index[hour]);
        bytes32 minute = toKey(timestamp, 1 minutes);
        if (minute < low || minute > high) {
            if (minute < low || low == 0) {
                low = minute;
            }
            if (minute > high) {
                high = minute;
            }
            index[hour] = toValue(low, high);
        }

        (low, high) = fromValue(index[minute]);
        bytes32 tsKey = toKey(timestamp);
        if (tsKey < low || tsKey > high) {
            if (tsKey < low || low == 0) {
                low = tsKey;
            }
            if (tsKey > high) {
                high = tsKey;
            }
            index[minute] = toValue(low, high);
        }

        index[tsKey] = _key;
    }

    function findFloorKeyYear(uint _timestamp, bytes32 _low, bytes32 _high) view internal returns (bytes32) {
        bytes32 year = toKey(_timestamp, 1 years);
        if (year < _low) {
            return 0;
        }
        if (year > _high) {
            // week
            (low, high) = fromValue(index[_high]);
            // hour
            (low, high) = fromValue(index[high]);
            // minute
            (low, high) = fromValue(index[high]);
            // ts
            (low, high) = fromValue(index[high]);
            return index[high];
        }

        bytes32 low;
        bytes32 high;

        while (year >= _low) {
            (low, high) = fromValue(index[year]);
            if (low != 0) {
                bytes32 key = findFloorKeyWeek(_timestamp, low, high);
                if (key != 0) {
                    return key;
                }
            }
            // 0x1e13380 = 1 years
            assembly {
                year := sub(year, 0x1e13380)
            }
        }

        return 0;
    }

    function findFloorKeyWeek(uint _timestamp, bytes32 _low, bytes32 _high) view internal returns (bytes32) {
        bytes32 week = toKey(_timestamp, 1 weeks);
        if (week < _low) {
            return 0;
        }

        bytes32 low;
        bytes32 high;

        if (week > _high) {
            // hour
            (low, high) = fromValue(index[_high]);
            // minute
            (low, high) = fromValue(index[high]);
            // ts
            (low, high) = fromValue(index[high]);
            return index[high];
        }

        while (week >= _low) {
            (low, high) = fromValue(index[week]);
            if (low != 0) {
                bytes32 key = findFloorKeyHour(_timestamp, low, high);
                if (key != 0) {
                    return key;
                }
            }

            // 1 weeks = 604800
            assembly {
                week := sub(week, 604800)
            }
        }
        return 0;
    }


    function findFloorKeyHour(uint _timestamp, bytes32 _low, bytes32 _high) view internal returns (bytes32) {
        bytes32 hour = toKey(_timestamp, 1 hours);
        if (hour < _low) {
            return 0;
        }

        bytes32 low;
        bytes32 high;

        if (hour > _high) {
            // minute
            (low, high) = fromValue(index[_high]);
            // ts
            (low, high) = fromValue(index[high]);
            return index[high];
        }

        while (hour >= _low) {
            (low, high) = fromValue(index[hour]);
            if (low != 0) {
                bytes32 key = findFloorKeyMinute(_timestamp, low, high);
                if (key != 0) {
                    return key;
                }
            }

            // 1 hours = 3600
            assembly {
                hour := sub(hour, 3600)
            }
        }
        return 0;
    }

    function findFloorKeyMinute(uint _timestamp, bytes32 _low, bytes32 _high) view internal returns (bytes32) {
        bytes32 minute = toKey(_timestamp, 1 minutes);
        if (minute < _low) {
            return 0;
        }

        bytes32 low;
        bytes32 high;

        if (minute > _high) {
            // ts
            (low, high) = fromValue(index[_high]);
            return index[high];
        }

        while (minute >= _low) {
            (low, high) = fromValue(index[minute]);
            if (low != 0) {
                bytes32 key = findFloorKeyTimestamp(_timestamp, low, high);
                if (key != 0) {
                    return key;
                }
            }

            // 1 minutes = 60
            assembly {
                minute := sub(minute, 60)
            }
        }

        return 0;
    }

    function findFloorKeyTimestamp(uint _timestamp, bytes32 _low, bytes32 _high) view internal returns (bytes32) {
        bytes32 tsKey = toKey(_timestamp);
        if (tsKey < _low) {
            return 0;
        }
        if (tsKey > _high) {
            return index[_high];
        }

        while (tsKey >= _low) {
            bytes32 key = index[tsKey];
            if (key != 0) {
                return key;
            }
            assembly {
                tsKey := sub(tsKey, 1)
            }
        }
        return 0;
    }

    function findFloorKey(uint _timestamp) view public returns (bytes32) {
//        require(_timestamp > 0xffffffff);
//        if (_timestamp < 1515612415) {
//            return 0;
//        }

        bytes32 yearLow;
        bytes32 yearHigh;
        (yearLow, yearHigh) = fromValue(head);

        return findFloorKeyYear(_timestamp, yearLow, yearHigh);
    }

    function toKey(uint _timestamp, uint rounder) pure internal returns (bytes32 result) {
        // 0x0...00000000000000000
        //        ^^^^^^^^ - rounder marker (eg, to avoid crossing first day of year with year)
        //                ^^^^^^^^ - rounded moment (year, week, etc)
        assembly {
            result := or(mul(rounder, 0x100000000), mul(div(_timestamp, rounder), rounder))
        }
    }

    function toValue(bytes32 _lowKey, bytes32 _highKey) pure internal returns (bytes32 result) {
        assembly {
            result := or(mul(_lowKey, 0x10000000000000000), _highKey)
        }
    }

    function fromValue(bytes32 _value) pure internal returns (bytes32 _lowKey, bytes32 _highKey) {
        assembly {
            _lowKey := and(div(_value, 0x10000000000000000), 0xffffffffffffffff)
            _highKey := and(_value, 0xffffffffffffffff)
        }
    }


    function toKey(uint timestamp) pure internal returns (bytes32) {
        return bytes32(timestamp);
    }
}
