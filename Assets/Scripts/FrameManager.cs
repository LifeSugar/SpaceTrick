using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FrameManager : MonoBehaviour
{
    // Start is called before the first frame update
void Start()
{
    QualitySettings.vSyncCount = 0;
    
    Application.targetFrameRate = (int)Mathf.Round((float)Screen.currentResolution.refreshRateRatio.value);

}
    // Update is called once per frame
    void Update()
    {
        
    }
}
