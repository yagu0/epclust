#define __STDC_FORMAT_MACROS //to print 64bits unsigned integers
#include <inttypes.h>
#include <cgds/Vector.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <stdio.h>

// Read an integer char by char, and position the cursor to next character
char readInt(FILE* stream, int* integer)
{
	*integer = 0;
	char curChar = fgetc(stream);
	int sign = (curChar == '-' ? -1 : 1);
	while (curChar < '0' || curChar > '9')
		curChar = fgetc(stream);
	while (curChar >= '0' && curChar <= '9')
	{
		*integer = 10 * (*integer) + (int) (curChar - '0');
		curChar = fgetc(stream);
	}
	(*integer) *= sign;
	return curChar; //separator, endline or .,e,E (if inside readReal)
}

// Read a real number char by char, and position the cursor to next character
char readReal(FILE* stream, float* real)
{
	int integerPart, exponent = 0, fractionalPart = 0, countZeros = 0;
	char curChar = readInt(stream, &integerPart);
	if (curChar == '.')
	{
		//need to count zeros
		while ((curChar = fgetc(stream)) == '0')
			countZeros++;
		if (curChar >= '1' && curChar <= '9')
		{
			ungetc(curChar, stream);
			curChar = readInt(stream, &fractionalPart);
		}
	}
	if (curChar == 'e' || curChar == 'E')
		curChar = readInt(stream, &exponent);
	*real = ( integerPart + (integerPart>=0 ? 1. : -1.) * (float)fractionalPart
		/ pow(10,countZeros+floor(log10(fractionalPart>0 ? fractionalPart : 1)+1)) )
			* pow(10,exponent);

	return curChar; //separator or endline
}

// Parse a line into integer+float (ID, value)
static void scan_line(FILE* ifile, char sep,
	int posID, int* ID, int posValue, float* value)
{
	char curChar;
	int position = 1;
	while (1)
	{
		if (position == posID)
			curChar = readInt(ifile, ID);
		else if (position == posValue)
			curChar = readReal(ifile, value);
		else
			curChar = fgetc(ifile); //erase the comma (and skip field then)

		// Continue until next separator (or line end or file end)
		while (!feof(ifile) && curChar != '\n' && curChar != sep)
			curChar = fgetc(ifile);
		position++;

		if (curChar == '\n' || feof(ifile))
		{
			// Reached end of line
			break;
		}
	}
}

// Main job: parse a data file into a conventional CSV file in rows, without header
// Current limitations:
//  - remove partial series (we could fill missing values instead)
//  - consider missing fields == 0 (if ,,)
//  - IDs should be st. pos. integers
//  - UNIX linebreaks only (\n)
int transform(const char* ifileName, int posID, int posValue,
	const char* ofileName, int nbItems, char sep)
{
	uint64_t processedLines = 0; //execution trace
	uint32_t seriesCount=0, skippedSeriesCount=0, mismatchLengthCount=0;
	int tsLength, lastID=0, ID, firstID, eof;
	float value, tmpVal;
	Vector* tsBuffer = vector_new(float);
	FILE* ifile = fopen(ifileName, "r");
	// Output file to write time-series sequentially, CSV format.
	FILE* ofile = fopen(ofileName, "w");

	// Skip header
	char curChar;
	do
		curChar = fgetc(ifile);
	while (curChar != '\n');

	// Process one client (ID in first column) at a time
	while (1)
	{

		eof = feof(ifile);
		if (!eof)
		{
			// Is there anything left to read? (file may end with '\n')
			curChar = fgetc(ifile);
			if (!feof(ifile) && curChar != '\n')
			{
				// Yes: read current line
				ungetc(curChar, ifile);
				scan_line(ifile, sep, posID, &ID, posValue, &value);
			}
			else
				eof = 1;
		}

		if (ID != lastID || eof)
		{
			if (lastID > 0)
			{
				// Just starting a new time-series (or EOF): process the last one
				if (tsLength == vector_size(tsBuffer))
				{
					for (int i=0; i<tsLength-1; i++)
					{
						vector_get(tsBuffer, i, tmpVal);
						fprintf(ofile, "%g%c", tmpVal, sep);
					}
					vector_get(tsBuffer, tsLength-1, tmpVal);
					fprintf(ofile, "%g\n", tmpVal);
					seriesCount++;
					if (nbItems > 0 && ++seriesCount >= nbItems)
						break;
				}
				else
				{
					// Mismatch lengths: skip series
					mismatchLengthCount++;
				}
			}
			else
				firstID = ID;
			if (eof)
			{
				// Last serie is processed
				break;
			}
			// Reinitialize current index of new serie
			tsLength = 0;
			lastID = ID;
		}

		// Fill values buffer
		if (ID != firstID)
		{
			if (tsLength < vector_size(tsBuffer))
				vector_set(tsBuffer, tsLength, value);
		}
		else
		{
			// First serie is reference: push all values
			vector_push(tsBuffer, value);
		}
		tsLength++;

		if ((++processedLines) % 1000000 == 0)
			fprintf(stdout,"Processed %"PRIu64" lines\n", processedLines);
	}

	// finally print some statistics
	fprintf(stdout,"NOTE: %u series retrieved.\n",seriesCount);
	if (mismatchLengthCount > 0)
		fprintf(stdout,"WARNING: %u mismatch series lengths.\n",mismatchLengthCount);

	fclose(ifile);
	fclose(ofile);
	return 0;
}

int main(int argc, char** argv)
{
	if (argc < 4) //program name + 3 arguments
	{
		printf("Usage: transform ifileName posID posValue [ofileName [nbItems [sep]]]\n \
  - ifileName: name of by-columns CSV input file\n \
  - posID: position of the identifier in a line (start at 1)\n \
  - posValue: position of the value of interest in a line\n \
  - ofileName: name of the output file; default: out.csv\n \
  - nbItems: number of series to retrieve; default: 0 (all)\n \
  - sep: fields separator; default: ','\n");
		return 0;
	}
	else
	{
		return transform(argv[1], atoi(argv[2]), atoi(argv[3]),
			argc > 4 ? argv[4] : "out.csv",
			argc > 5 ? atoi(argv[5]) : 0,
			argc > 6 ? argv[6][0] : ',');
	}
}
