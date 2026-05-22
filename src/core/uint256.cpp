#include "uint256.h"
#include <stdio.h>
#include <algorithm>

base_blob::base_blob(const std::vector<uint8_t>& vch)
{
    if (vch.size() == WIDTH)
        memcpy(data, &vch[0], WIDTH);
    else
        memset(data, 0, WIDTH);
}

bool base_blob::IsNull() const
{
    for (int i = 0; i < WIDTH; i++)
        if (data[i] != 0)
            return false;
    return true;
}

void base_blob::SetNull()
{
    memset(data, 0, WIDTH);
}

int base_blob::Compare(const base_blob& other) const
{
    for (int i = WIDTH - 1; i >= 0; i--)
    {
        if (data[i] < other.data[i])
            return -1;
        if (data[i] > other.data[i])
            return 1;
    }
    return 0;
}

std::string base_blob::GetHex() const
{
    char psz[WIDTH * 2 + 1];
    for (int i = 0; i < WIDTH; i++)
        sprintf(psz + i * 2, "%02x", data[WIDTH - i - 1]);
    return std::string(psz, psz + WIDTH * 2);
}

void base_blob::SetHex(const char* psz)
{
    memset(data, 0, WIDTH);
    while (isspace(*psz)) psz++;
    if (psz[0] == '0' && tolower(psz[1]) == 'x') psz += 2;
    const char* pbegin = psz;
    while (isxdigit(*psz)) psz++;
    psz--;
    unsigned char* pdata = data;
    while (psz >= pbegin && pdata < data + WIDTH)
    {
        unsigned char c = (unsigned char)tolower(*psz--);
        if (isdigit(c)) *pdata = c - '0';
        else *pdata = c - 'a' + 10;
        if (psz >= pbegin)
        {
            c = (unsigned char)tolower(*psz--);
            if (isdigit(c)) *pdata |= (c - '0') << 4;
            else *pdata |= (c - 'a' + 10) << 4;
        }
        pdata++;
    }
}

void base_blob::SetHex(const std::string& str)
{
    SetHex(str.c_str());
}

std::string base_blob::ToString() const
{
    return GetHex();
}
