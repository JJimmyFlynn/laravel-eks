import http from 'k6/http'
import { sleep } from 'k6'
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js'

export const options = {
    stages: [
        {'duration': '2m', target: 50},
        {'duration': '10m', target: 50},
        {'duration': '2m', target: 0},
    ]
}

export default function () {
    http.get('https://laravel-k8s.johnjflynn.net')
    sleep(randomIntBetween(2, 8))
}
