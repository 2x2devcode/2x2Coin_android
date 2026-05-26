// Copyright (c) 2026 - 2X2Coin Project
// Buffer sensível com limpeza explícita da RAM no destrutor

#pragma once

#include <vector>
#include <cstdint>
#include <cstring>
#include <algorithm>

namespace Coin2x2 {

template <typename T = uint8_t>
class SecureBuffer {
public:
    SecureBuffer() = default;
    explicit SecureBuffer(size_t size) : m_data(size) {}
    explicit SecureBuffer(std::vector<T> data) : m_data(std::move(data)) {}

    SecureBuffer(const SecureBuffer&) = delete;
    SecureBuffer& operator=(const SecureBuffer&) = delete;

    SecureBuffer(SecureBuffer&& other) noexcept
        : m_data(std::move(other.m_data))
    {
        other.m_data.clear();
    }

    SecureBuffer& operator=(SecureBuffer&& other) noexcept {
        if (this != &other) {
            wipe();
            m_data = std::move(other.m_data);
            other.m_data.clear();
        }
        return *this;
    }

    ~SecureBuffer() { wipe(); }

    T* data() { return m_data.data(); }
    const T* data() const { return m_data.data(); }
    size_t size() const { return m_data.size(); }
    bool empty() const { return m_data.empty(); }

    void resize(size_t n) {
        if (n < m_data.size()) {
            wipeRange(n, m_data.size());
        }
        m_data.resize(n);
    }

    void assign(const T* src, size_t count) {
        wipe();
        m_data.assign(src, src + count);
    }

    void wipe() {
        if (!m_data.empty()) {
            volatile T* p = m_data.data();
            std::fill(m_data.begin(), m_data.end(), T(0));
            (void)p;
            m_data.clear();
            m_data.shrink_to_fit();
        }
    }

private:
    void wipeRange(size_t from, size_t to) {
        if (from < to && to <= m_data.size()) {
            std::fill(m_data.begin() + static_cast<ptrdiff_t>(from),
                      m_data.begin() + static_cast<ptrdiff_t>(to), T(0));
        }
    }

    std::vector<T> m_data;
};

} // namespace Coin2x2
