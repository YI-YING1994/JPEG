#include <iostream>
#include <string>
#include <map>
using namespace std;
int main()
{
	
	string input,ounput;
	map<char,string> table; 
	table['0'] = "0000";
	table['1'] = "0001";
	table['2'] = "0010";
	table['3'] = "0011";
	table['4'] = "0100";
	table['5'] = "0101";
	table['6'] = "0110";
	table['7'] = "0111";
	table['8'] = "1000";
	table['9'] = "1001";
	table['A'] = "1010";
	table['B'] = "1011";
	table['C'] = "1100";
	table['D'] = "1101";
	table['E'] = "1110";
	table['F'] = "1111";
	table[' '] = "";
	getline(cin, input);
	for(int i=0;i<input.size();i++)
		cout<<table[input[i]];
} 
