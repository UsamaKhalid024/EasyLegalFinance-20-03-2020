/**
*    @description : Helper class for EFT file creation
**/
public with sharing class EFTHelper {

    /**
	*    @description : Method to add leading spaces or characters 
	**/
    public static String formatString(String stringToFormat,String characterToAdd, Integer fieldSize, String extraCharsSide){
       	String formattedString = '';
        if(stringToFormat.length() >= fieldSize) return stringToFormat.substring(0, fieldSize);
        for(Integer i=0;i<(fieldSize-(!String.isBlank(stringToFormat) ? stringToFormat.length() : 0));i++){
            formattedString += (!String.isBlank(characterToAdd) ? characterToAdd : ' ');
        }
        if (extraCharsSide == 'left') {
            return formattedString + stringToFormat;
        } else {
            return stringToFormat + formattedString;
        }
    }
}