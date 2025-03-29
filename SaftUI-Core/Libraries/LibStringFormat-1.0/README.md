#LibStringFormat-1.0

	Author: Safturento
	Website: www.safturento.com
	Description: Adds a variety of functions used to easily format strings and numbers 
	Dependencies: LibStub
	License: LGPL v2.1

## Documentation

#### SanitizeNumber(stringOrNumber [,min [,max]])
###### removes any character that would render the number invalid; optionally, you can pass a min and max to give the number a size limitation
	<stringOrNumber> (string or number) - the value that you want to sanitize
	<min> [optional] (number) - the minimum that the number can be
	<max> [optional] (number) - the maximum that the number can be
 
#### Trim(string)
###### removes extra whitespace from a string
	<string> (string) - the string you wish to trim

#### ToClock(sec)
###### converts seconds into a clock format
	<sec> (number) - number of seconds to format

#### ToTime(sec)
###### converts seconds into a readable time format
	<sec> (number) - number of seconds to format

#### ToHex(r, g, b)
###### converts RGB values intoa hexadecimal string
	<r>,<g>,<b> - (number) RGB color values, can be passed in values of 0-1 or 0-255

#### ToRGB(hexString [,divide])
###### converts hexadecimal strings into RGB values
	<hexString> (string) - the hexadecimal string you wish to convert to RGB values
	<divide> [optional] (boolean) - set to true if you want the values returned in 0-1 values instead of 0-255

#### ColorString(string, [r,g,b] or [hexString])
###### pass a string and color (either using a hex string or RGB values) to get that string in your color of choice
	<string> (string) - the string that you wish to colorize
	<hexString> (string) - you can pass a hex string you wish to use to colorize the text
	<r>,<g>,<b> - (number) - you can pass a set of 3 RGB values which will be converted to colorize the text

#### ShortFormat(value [,decimals])
###### returns the abbreviated form of a number
	<value> (number) - the number you wish to format
	<decimals> [optional] (number) -- the amount of decimals you wish to show. Default is 0

#### FileSizeFormat(value [,decimals])
###### formats bytes into a readable file size format
	<value> (number) - the number you wish to format
	<decimals> [optional] (number) -- the amount of decimals you wish to show. Default is 0

#### CommaFormat(value)
###### comma separates a number
	<value> (number) - the number you wish to format

#### GoldFormat(money [,round])
###### returns a number in the form of gold, silver and copper
	<money> (number) - the amount of money you wish to format
	<round> [optional] (boolean) - if set to true, only show the highest currency