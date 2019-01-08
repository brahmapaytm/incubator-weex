/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#pragma once

#include <wtf/Optional.h>
#include <wtf/TriState.h>

namespace JSC {

class DefinePropertyAttributes {
public:
    static_assert(FalseTriState == 0, "FalseTriState is 0.");
    static_assert(TrueTriState == 1, "TrueTriState is 1.");
    static_assert(MixedTriState == 2, "MixedTriState is 2.");

    static const unsigned ConfigurableShift = 0;
    static const unsigned EnumerableShift = 2;
    static const unsigned WritableShift = 4;
    static const unsigned ValueShift = 6;
    static const unsigned GetShift = 7;
    static const unsigned SetShift = 8;

    DefinePropertyAttributes()
        : m_attributes(
            (MixedTriState << ConfigurableShift)
            | (MixedTriState << EnumerableShift)
            | (MixedTriState << WritableShift)
            | (0 << ValueShift)
            | (0 << GetShift)
            | (0 << SetShift))
    {
    }

    explicit DefinePropertyAttributes(unsigned attributes)
        : m_attributes(attributes)
    {
    }

    unsigned rawRepresentation() const
    {
        return m_attributes;
    }

    bool hasValue() const
    {
        return m_attributes & (0b1 << ValueShift);
    }

    void setValue()
    {
        m_attributes = m_attributes | (0b1 << ValueShift);
    }

    bool hasGet() const
    {
        return m_attributes & (0b1 << GetShift);
    }

    void setGet()
    {
        m_attributes = m_attributes | (0b1 << GetShift);
    }

    bool hasSet() const
    {
        return m_attributes & (0b1 << SetShift);
    }

    void setSet()
    {
        m_attributes = m_attributes | (0b1 << SetShift);
    }

    bool hasWritable() const
    {
        return extractTriState(WritableShift) != MixedTriState;
    }

    std::optional<bool> writable() const
    {
        if (!hasWritable())
            return std::nullopt;
        return extractTriState(WritableShift) == TrueTriState;
    }

    bool hasConfigurable() const
    {
        return extractTriState(ConfigurableShift) != MixedTriState;
    }

    std::optional<bool> configurable() const
    {
        if (!hasConfigurable())
            return std::nullopt;
        return extractTriState(ConfigurableShift) == TrueTriState;
    }

    bool hasEnumerable() const
    {
        return extractTriState(EnumerableShift) != MixedTriState;
    }

    std::optional<bool> enumerable() const
    {
        if (!hasEnumerable())
            return std::nullopt;
        return extractTriState(EnumerableShift) == TrueTriState;
    }

    void setWritable(bool value)
    {
        fillWithTriState(value ? TrueTriState : FalseTriState, WritableShift);
    }

    void setConfigurable(bool value)
    {
        fillWithTriState(value ? TrueTriState : FalseTriState, ConfigurableShift);
    }

    void setEnumerable(bool value)
    {
        fillWithTriState(value ? TrueTriState : FalseTriState, EnumerableShift);
    }

private:
    void fillWithTriState(TriState state, unsigned shift)
    {
        unsigned mask = 0b11 << shift;
        m_attributes = (m_attributes & ~mask) | (state << shift);
    }

    TriState extractTriState(unsigned shift) const
    {
        return static_cast<TriState>((m_attributes >> shift) & 0b11);
    }

    unsigned m_attributes;
};


} // namespace JSC
