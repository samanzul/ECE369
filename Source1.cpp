#include <stdio.h>
#include <math.h>

int trajectory = 0;
int pass = 0;

int increment(int row, int col, int index) {

	if (index < col && pass == 0) { // top row
		index++;
		pass = 1;
		trajectory = 0;
	}
	else if (index > (col * (row - 1) - 1) && pass == 0) { // bottom row
		index++;
		pass = 1;
		trajectory = 1;
	}
	else if ((index % col) == 0 && pass == 0) { // left column
		index = index + col;
		pass = 1;
		trajectory = 1;
	}
	else if (((index + 1) % col) == 0 && pass == 0) { // right column
		index = index + col;
		pass = 1;
		trajectory = 0;
	}
	else {
		if (trajectory == 0) {
			index = index + col - 1;
		}
		if (trajectory == 1) {
			index = index - col + 1;
		}
		pass = 0;
	}

	return index;
}

int SAD(int index, int frame[], int window[], int winRowSize, int winColSize, int fraRowSize, int fraColSize) {

	int sum = 0;
	int count = 0;
	if (((index % winRowSize) + fraRowSize) > winRowSize && ((winRowSize * winColSize) - winRowSize * fraColSize) < (fraColSize + index)) {
		return 10000;
	}
	for (int i = 0; i < fraColSize; i++) {
		for (int j = 0; j < fraRowSize; j++) {
			sum = sum + abs(frame[count] - window[j + index + winRowSize * i]);
			//printf("|%d - %d| = %d\n", frame[count], window[j + index + winRowSize * i], sum);
			count++;
		}
	}
	//printf("%d ", sum);
	return sum;
}

int main(void) {
	const int winRowSize = 8;
	const int winColSize = 4;
	const int fraRowSize = 2;
	const int fraColSize = 2;
	int frame[fraRowSize * fraColSize];
	int window[winRowSize * winColSize];
	int index = 0;
	int minIndex = 0;

	for (int i = 0; i < (winRowSize * winColSize); i++) {
		window[i] = i;
		//printf("%d ", window[i]);
	}
	//printf("\n");

	frame[0] = 8;
	frame[1] = 9;
	frame[2] = 16;
	frame[3] = 17;
	//printf("\n");
	SAD(index, frame, window, winRowSize, winColSize, fraRowSize, fraColSize);

	for (int i = 0; i < (winRowSize * winColSize); i++) {
		//printf("%d ", index);
		index = increment(winRowSize, winColSize, index);
		if (SAD(minIndex, frame, window, winRowSize, winColSize, fraRowSize, fraColSize) > SAD(index, frame, window, winRowSize, winColSize, fraRowSize, fraColSize)) {
			minIndex = index;
		}
	}
	printf("\nLocation = %d\n", minIndex);


	return 0;
}