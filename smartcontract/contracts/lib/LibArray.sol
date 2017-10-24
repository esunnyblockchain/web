pragma solidity ^0.4.11;
import "./LibString.sol";
library LibArray
{
    function deleteElement(string[] storage self, string element)
    {
        uint j = 0;
        for (uint i = 0 ; i < self.length; ++i) 
        {
            if (LibString.equals(self[i], element)) 
            {
                j++; //
                continue;
            }
            if(j != 0)
            {
                self[i-j] = self[i];
            }
        }
        self.length = self.length - j;
    }
    function deleteElement(bytes32[] storage self, bytes32 element)
    {
        uint j = 0;
        for (uint i = 0 ; i < self.length; ++i) 
        {
            if (self[i] == element) 
            {
                j++; //
                continue;
            }
            if(j != 0)
            {
                self[i-j] = self[i];
            }
        }
        self.length = self.length - j;
    }
    function deleteElement(uint[] storage self, uint element)
    {
        uint j = 0;
        for (uint i = 0 ; i < self.length; ++i) 
        {
            if (self[i] == element) 
            {
                j++; //
                continue;
            }
            if(j != 0)
            {
                self[i-j] = self[i];
            }
        }
        self.length = self.length - j;
    }
}

