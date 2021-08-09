#include "Util.hpp"

double vectorMean(std::vector<double>& v)
{
	int items = v.size();
	double sum = std::accumulate(v.begin(), v.end(), 0.0);

	return sum / items;
}

double vectorMean(std::vector<int>& v) 
{
	int items = v.size();
	double sum = std::accumulate(v.begin(), v.end(), 0.0);

	return sum / items;
}

double vectorVar(std::vector<double>& v)
{
	int items = v.size();
	double mean = vectorMean(v);
	double sqSum = 0.0;

	for (int i = 0; i < items; i++) {
		sqSum += pow(v[i]-mean, 2);
	}

	return sqSum / items;
}

double vectorVar(std::vector<int>& v)
{
	int items = v.size();
	double mean = vectorMean(v);
	double sqSum = 0.0;

	for (int i = 0; i < items; i++) {
		sqSum += pow(v[i]-mean, 2);
	}

	return sqSum / items;
}

int isolateHatchResults(std::vector<std::string> results, std::string key)
{
	int ret = 0;
	for (unsigned int i = 0; i < results.size(); i++) {
		if (results[i].compare(key) == 0) {
			ret++;
		}
	}
	return ret;
}


std::vector<double> paramVector(const double p[3]) 
{
	double min = p[0];
	double max = p[1];
	double by = p[2];

	std::vector<double> ret;
	for (double i = min; i <= max; i+=by) {
		ret.push_back(i);
	}

	return ret;
}


void printBoutInfo(std::string fname, std::string model, std::string tag, std::vector<int> v) 
{
	std::ofstream of;
	of.open("Output/" + fname, std::ofstream::app);

	for (unsigned int i = 0; i < v.size(); i++) {
		of << model << "," << tag << "," << v[i] << "\n";
	}

	of.close();
}

std::string checkSeasonSuccess(Parent& pf, Parent& pm, Egg& egg) 
{
	if (egg.isHatched() && egg.isAlive()) {
		return "hatched";
	} else if (!egg.isHatched() && !egg.isAlive()) {
		return "allFail";
	} else if (!egg.isHatched()) {
		return "eggTimeFail";
	} else if (!egg.isAlive()) {
		return "eggColdFail";
	} 
	return "unknownFail";
}

void printDailyInfo(Parent& pf, Parent& pm, Egg& egg) {
	int days = egg.getIncubationDays();
	double maxDays = egg.getMaxHatchDays();
	int eggNeglect = egg.getTotNeg();

	double femaleEnergy = pf.getEnergy();
	std::string femaleState = pf.getStrState();

	double maleEnergy = pm.getEnergy();
	std::string maleState = pm.getStrState();

	std::cout << "On day " << days << " of " << maxDays
	   	  << " with egg neglect " << eggNeglect << ".///"
	   	  << " Female is " << femaleState
	   	  << " with " << femaleEnergy << " energy.///"
	   	  << " Male is " << maleState
	   	  << " with " << maleEnergy << " energy.///\n";
}
