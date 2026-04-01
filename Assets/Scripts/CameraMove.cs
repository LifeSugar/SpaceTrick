using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Controls camera movement and rotation based on mouse and keyboard input.
/// </summary>
public class CameraMove : MonoBehaviour
{
    /// <summary>
    /// Mouse sensitivity for horizontal rotation.
    /// </summary>
    public float sensitivityX = 10.0f;

    /// <summary>
    /// Mouse sensitivity for vertical rotation.
    /// </summary>
    public float sensitivityY = 10.0f;

    /// <summary>
    /// Minimum vertical angle (in degrees) the camera can rotate to.
    /// </summary>
    public float minmumY = -60f;

    /// <summary>
    /// Maximum vertical angle (in degrees) the camera can rotate to.
    /// </summary>
    public float maxmunY = 60f;

    /// <summary>
    /// Speed at which the camera moves.
    /// </summary>
    public float moveSpeed = 5f;

    /// <summary>
    /// Current vertical rotation value.
    /// </summary>
    float rotationY = 0f;

    /// <summary>
    /// Handles camera rotation and movement every frame based on user input.
    /// </summary>
    void Update()
    {
        // Prevent camera movement and rotation when Left Alt is held down
        if (Input.GetKey(KeyCode.LeftAlt)) return;

        // Get the current horizontal rotation (Y axis)
        float rotationX = transform.localEulerAngles.y;

        // If right mouse button is held, update rotation based on mouse movement
        if(Input.GetMouseButton(1))
        {
            // Adjust horizontal rotation by mouse X movement
            rotationX += Input.GetAxis("Mouse X") * sensitivityX;
            // Adjust vertical rotation by mouse Y movement
            rotationY += Input.GetAxis("Mouse Y") * sensitivityY;
        }

        // Clamp the vertical rotation to prevent flipping
        rotationY = Clamp(rotationY, maxmunY, minmumY);

        // Apply the calculated rotation to the camera
        transform.localEulerAngles = new Vector3(-rotationY, rotationX, 0);

        // Calculate movement direction based on input axes
        Vector3 move = transform.right * Input.GetAxis("Horizontal") + Input.GetAxis("Vertical") * transform.forward;

        // Handle vertical movement (Q for up, E for down)
        float upOrDown = 0f;
        if (Input.GetKey(KeyCode.Q))
            upOrDown = 1f;
        if (Input.GetKey(KeyCode.E))
            upOrDown = -1f;

        // Add vertical movement to the move vector
        move += Vector3.up * upOrDown;

        // Move the camera based on the calculated direction and speed
        transform.position += move * moveSpeed * Time.deltaTime;
    }

    /// <summary>
    /// Clamps a value between a minimum and maximum value.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="max">The maximum allowed value.</param>
    /// <param name="min">The minimum allowed value.</param>
    /// <returns>The clamped value.</returns>
    public float Clamp(float value, float max, float min)
    {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    /// <summary>
    /// Initializes the camera by freezing the Rigidbody's rotation if present.
    /// </summary>
    void Start()
    {
        // Get the Rigidbody component attached to this GameObject
        Rigidbody rigidbody = GetComponent<Rigidbody>();
        if (rigidbody)
        {
            // Prevent the Rigidbody from rotating due to physics
            rigidbody.freezeRotation = true;
        }
    }
}