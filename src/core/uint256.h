#ifndef UINT256_H
#define UINT256_H

#include <string>
#include <vector>
#include <stdint.h>
#include <string.h>

class base_blob
{
protected:
    enum { WIDTH=32 };
    uint8_t data[WIDTH];
public:
    base_blob()
    {
        memset(data, 0, sizeof(data));
    }
    explicit base_blob(const std::vector<uint8_t>& vch);
    bool IsNull() const;
    void SetNull();
    int Compare(const base_blob& other) const;
    friend bool operator==(const base_blob& a, const base_blob& b) { return a.Compare(b) == 0; }
    friend bool operator!=(const base_blob& a, const base_blob& b) { return a.Compare(b) != 0; }
    friend bool operator<(const base_blob& a, const base_blob& b) { return a.Compare(b) < 0; }
    std::string GetHex() const;
    void SetHex(const char* psz);
    void SetHex(const std::string& str);
    std::string ToString() const;
    unsigned char* begin() { return &data[0]; }
    unsigned char* end() { return &data[WIDTH]; }
    const unsigned char* begin() const { return &data[0]; }
    const unsigned char* end() const { return &data[WIDTH]; }
    unsigned int size() const { return WIDTH; }
};

class uint256 : public base_blob
{
public:
    uint256() {}
    uint256(const base_blob& b) : base_blob(b) {}
    explicit uint256(const std::vector<uint8_t>& vch) : base_blob(vch) {}
};

#endif
