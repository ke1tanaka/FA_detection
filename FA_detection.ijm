// Choose a main directory and get file list
mainDir = getDirectory("Choose a main directory "); 
mainList = getFileList(mainDir);

// Set image threshold parameters
threshold_min = 18000
threshold_max = 65535

// Define parameters for focal adhesion size and circularity
minSize = 10;
maxSize = "Infinity";
minCircularity = 0.05;
maxCircularity = 0.75;

// Create a parameter string using the defined values
particleAnalysisParams = "size=" + minSize + "-" + maxSize +
                         " circularity=" + minCircularity + "-" + maxCircularity +
                         " pixel exclude add";

// Start making focal adhesion masks
// Set measurement parameters for analyzing images
run("Set Measurements...", "area mean min fit feret's perimeter redirect=None decimal=3");

// Iterate over each file in the main folder
for (i=0; i<mainList.length; i++) {
			// Check if the file is tif 
			if(endsWith(mainList[i],".tif")){
				// Open the image file
				open(mainDir + mainList[i]);
				selectWindow(mainList[i]);
				
				// Apply a threshold to the image 
				setThreshold(threshold_min, threshold_max);
				setOption("BlackBackground", false);
				
				// Convert the thresholded image to a mask
				run("Convert to Mask");
				
				// Analyze particles in the image with specified size and circularity set above, 
				// excluding edge particles and adding them to ROI Manager
				run("Analyze Particles...", particleAnalysisParams);
				
				// Deselect any selected ROIs in the ROI Manager
				roiManager("Deselect");
				
				// Skip when FA is not detected
				if (roiManager("count") == 0){
					continue;
				} else {
				// Get file name
				filenameWithExtension = mainList[i];

				// Find the position of the last dot in the filename
				dotIndex = filenameWithExtension.lastIndexOf(".");
				
				// Get the filename without the extension using substring
				// If there's no dot, keep the original name
				if (dotIndex > -1) {
				    filenameWithoutExtension = filenameWithExtension.substring(0, dotIndex);
				} else {
				    filenameWithoutExtension = filenameWithExtension;
				}
				
				// Save the ROIs to a ZIP file
				roiManager("Save", mainDir + filenameWithoutExtension + "_FA.zip");			
				roiManager("Deselect");
				
				// Measure the all ROIs and save the results as a CSV file
				roiManager("Measure");
				selectWindow("Results");
				saveAs("Results", mainDir + filenameWithoutExtension + "_FA.csv");
				
				// Select all ROIs, combine them if multiple exist, 
				// and add to the manager again and save as one ROI
				selectWindow("ROI Manager");
				run("Select All");
				if (roiManager("count") > 1) {
					roiManager("Combine");
					roiManager("Add");
				}
				focal_adhesion_num = roiManager("count")-1;
				roiManager("Select", focal_adhesion_num);
				roiManager("Save", mainDir + filenameWithoutExtension + "_FA.roi");
		
				// Close various windows if open to prepare for the next iteration
				if (isOpen("Results")) {
				    selectWindow("Results"); 
     				run("Close" );
				}
				if (isOpen("Log")) {
         			selectWindow("Log");
         			run("Close" );
				}
				if (isOpen("ROI Manager")) {
         			selectWindow("ROI Manager");
         			roiManager("Deselect");
         			roiManager("Delete");
         			run("Close");
         		}
				while (nImages()>0) {
          			selectImage(nImages());  
          			run("Close");
				}
				}
			}
		//Free up memory before next iteration
		run("Collect Garbage");
}
// End making focal adhesion masks